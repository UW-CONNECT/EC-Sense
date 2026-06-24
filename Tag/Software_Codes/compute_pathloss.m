function [loss_top_tag, loss_tag_in_soil, loss_diff] = compute_pathloss(tag_loc, reader_loc, freq, VWC, snr)
    METHOD = 0;
    tx_power = 33;
%     v_sand = 0.5;
%     v_clay = 0.15;
%     bulk_density = 1.5;
%     v_sand = 0.216;
%     v_clay = 0.041;
%     bulk_density = 1.96;
    v_sand = 1;
    v_clay = 0;
    bulk_density = 1.52;
    v_silt = 1 - v_sand - v_clay;

    soil_bulk_density = 2.66;
    
    omega = 2 * pi * freq;
    T = 20;
    e_min = 4.9;
    tau_free = (1.1109e-10 + 3.824e-12 * T + 6.938e-14 * T^2 - 5.096e-16 * T^3) / 2 / pi;
    e_free_max = 88.045 - 0.4147 * T + 6.295e-4 * T^2 + 1.075e-5 * T^3;
    e_free_real = e_min + (e_free_max - e_min) / (1 + (omega * tau_free).^2);
    e_free_imag = omega * tau_free * (e_free_max - e_min) / (1 + (omega * tau_free).^2);
    e_free = e_free_real + 1j * e_free_imag;
    
    e_sand = 3 + 0.078j;
    e_silt = 5 + 0.078j;
    e_clay = 5 + 0.078j;
    e_soil = v_sand * e_sand + v_clay * e_clay + v_silt * e_clay;
    if METHOD == 1  
        param_a = 0.65;
        param_b_1 = 1.2748 - 0.519 * v_sand - 0.152 * v_clay; 
        param_b_2 = 1.33797 - 0.603 * v_sand - 0.166 * v_clay; 
        e_real = 1.15 * (1 + (bulk_density/soil_bulk_density)* real(e_soil)^param_a + (VWC^param_b_1)*(e_free_real^param_a) - VWC)^(1/param_a) - 0.68;
        e_imag = ((VWC^param_b_2)*(e_free_imag^param_a))^(1/param_a);
    else
        tau_bound = 1e-11;
        e_bound_max = -36 * v_clay + 44;
        e_bound_real = e_min + (e_bound_max - e_min) / (1 + (omega * tau_bound).^2);
        e_bound_imag = omega * tau_bound * (e_bound_max - e_min) / (1 + (omega * tau_bound).^2);
        e_bound = e_bound_real + 1j * e_bound_imag;
        e_air = 1;
        OM = 0;
        OC = OM * 0.58;
        wilting_point = 0.02982 + 0.089 * v_clay + 0.00786 * OM;
        p = 0.6819 - 0.0648 ./ (OC + 1) - 0.119 * bulk_density.^2 - 0.02668 ...
            + 0.1489 * v_clay + 0.08031 * v_silt + 0.02321 ./ ((OC + 1) .* (bulk_density.^2)) ...
            - 0.01908 * bulk_density.^2 - 0.1109 * v_clay - 0.2315 * v_clay * v_silt ...
            - 0.01197 * v_silt* bulk_density.^2 - 0.01068 * v_clay * bulk_density.^2;
        if VWC < wilting_point
            e_eff = (1 - p) * e_soil + VWC .* e_bound + (p - VWC) * e_air;
        elseif VWC >= wilting_point && VWC < p
            e_eff = (1 - p) * e_soil + ...
                 VWC * ((p - VWC) / (p - wilting_point)* e_bound + (VWC - wilting_point) / (p - wilting_point) * e_free) + ...
                 (p - VWC) * e_air;
        else
            e_eff = (1 - VWC) * e_soil + VWC .* e_free;
        end

        e_real = real(e_eff);
        e_imag = imag(e_eff);

    end
    loss_tan = e_imag/e_real;
    alpha = omega / 3e8 * sqrt(e_real/2*(sqrt(1+loss_tan^2)-1));
    beta = omega / 3e8 * sqrt(e_real/2*(sqrt(1+loss_tan^2)+1));
    soil_e = e_real/2 * (sqrt(1+loss_tan^2)+1);
    soil_n = sqrt(soil_e);
    
    
    dis_h = sqrt((tag_loc.x - reader_loc.x)^2 + (tag_loc.y - reader_loc.y)^2);
    syms x
    eqn = sin(atan(x/reader_loc.z)) == soil_n * sin(atan((dis_h-x)/tag_loc.z));
    S = vpasolve(eqn);
    inc_d = double(S);
    
    path_len_air = sqrt(inc_d^2 + reader_loc.z^2);
    path_len_soil = sqrt((dis_h - inc_d)^2 + tag_loc.z^2);
    path_len_top_tag = sqrt(dis_h^2 + reader_loc.z^2);
    
    if dis_h == 0
        eff_reader_loc_z = soil_n * reader_loc.z;
    else
        eff_reader_loc_z = inc_d * tag_loc.z / (dis_h - inc_d);
    end
    eff_path_len_air = sqrt(inc_d^2 + eff_reader_loc_z^2);
    fprintf("reader height: %.2f m, effective reader loc: %.2f m\n", reader_loc.z, eff_reader_loc_z);
    
    loss_top_tag = 20*log10(4*pi*path_len_top_tag*freq/3e8);
    
    loss_air = 20*log10(4*pi*path_len_air*freq/3e8);
%     loss_soil = 20 * log10(4*pi*freq*(path_len_air + path_len_soil)/(3e8)) -  loss_air + 20*log10(exp(1)) * alpha * path_len_soil;
%     loss_soil = 20 * log10(4*pi*freq*(path_len_air + path_len_soil)/3e8) -  loss_air + 20*log10(exp(1)) * alpha * path_len_soil;
    loss_soil = 20 * log10(4*pi*freq*(path_len_air + soil_n * path_len_soil)/3e8) -  loss_air + 20*log10(exp(1)) * alpha * path_len_soil;
%     loss_soil = 20 * log10(4*pi*freq*(soil_n * path_len_soil)/3e8) + 20*log10(exp(1)) * alpha * path_len_soil;
    
    cos_theta_I = reader_loc.z / path_len_air;
    sin_theta_I = inc_d / path_len_air;
    R_s = ((cos_theta_I - sqrt(soil_e - sin_theta_I^2)) / (cos_theta_I + sqrt(soil_e - sin_theta_I^2)))^2;
    R_p = ((soil_e * cos_theta_I - sqrt(soil_e - sin_theta_I^2)) / (soil_e * cos_theta_I + sqrt(soil_e - sin_theta_I^2)))^2;
    R = 0.5 * (R_s + R_p);
    loss_refraction = 10 * log10(1/(1 - R));
    
    % x = sqrt(soil_e - sin_theta_I^2);
    % y=cos_theta_I;
    % 10*log10((y+x)^2/4/y/x)
    
    loss_tag_in_soil = loss_air + loss_soil + loss_refraction;
    if snr ~= -1
        loss_tag_in_soil_1 = tx_power - awgn(tx_power-loss_tag_in_soil, snr, 'measured');
        loss_top_tag_1 = tx_power - awgn(tx_power-loss_top_tag, snr, 'measured');
    else
        loss_tag_in_soil_1 = loss_tag_in_soil;
        loss_top_tag_1 = loss_top_tag;
    end
    loss_diff = loss_tag_in_soil_1 - loss_top_tag_1;
    
    fprintf("VWC: %.2f, reader height: %.2f m, tag depth: %.2f m\n", VWC, reader_loc.z, tag_loc.z);
    fprintf("pathloss(top): %.3f, pathloss(bottom): %.3f, pathloss_diff: %.3f\n", loss_top_tag, loss_tag_in_soil, loss_diff);
end
