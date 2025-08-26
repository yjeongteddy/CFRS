function H_T = harmonic_mean_height(H1, d1, H2, d2)
    % Function to calculate harmonic mean height
    % Inputs:
    % H1 - First height
    % d1 - First depth
    % H2 - Second height
    % d2 - Second depth
    % Output:
    % H_T - Harmonic mean height

    % Calculate the harmonic mean height
    H_T = (H1/d1 + H2/d2) / (1/d1 + 1/d2);
end