function value = idw_interpolate(X, Y, Z, xq, yq, p)
    % IDW interpolation at point (xq, yq) using exponent p
    % X, Y, Z must be the same size
    % p is the power parameter (commonly 2)

    % Flatten arrays
    x = X(:);
    y = Y(:);
    z = Z(:);

    % Compute distances
    distances = sqrt((x - xq).^2 + (y - yq).^2);

    % Handle case where query point exactly matches a grid point
    tol = 1e-12;
    exact_match = distances < tol;
    if any(exact_match)
        value = z(exact_match);
        return;
    end

    % Compute weights
    weights = 1 ./ (distances .^ p);

    % Weighted average
    value = sum(weights .* z) / sum(weights);
end
