%% RESULTADOS TFG - EVOLUCION DE LA CONSTELACION
 
clear;

clc;

close all;
 
modos = ["BB_LB", "BB2", "UC_LB", "UC2"];
 
nombres = ["Banda base - Loopback", ...

           "Banda base - Dos RFSoC", ...

           "Upconverter - Loopback", ...

           "Upconverter - Dos RFSoC"];
 
for k = 1:length(modos)
 
    modo = modos(k);

    nombre = nombres(k);
 
    %% ========================================================

    % TX

    %% ========================================================
 
    [I_TX,Q_TX] = load16(modo + "_TX.csv",4,8);
 
    %% ========================================================

    % ADC

    %% ========================================================
 
    [I_ADC,Q_ADC] = load64(modo + "_ADC.csv",4,5);
 
    %% ========================================================

    % FILTRO ADAPTADO

    %% ========================================================
 
    [I_FILTRO,Q_FILTRO] = load64(modo + "_filtros.csv",4,5);
 
    %% ========================================================

    % GARDNER

    %% ========================================================
 
    [I_GARDNER,Q_GARDNER,valid] = loadGardner(modo + "_Gardner.csv");
 
    I_GARDNER = I_GARDNER(valid);

    Q_GARDNER = Q_GARDNER(valid);
 
    %% ========================================================

    % FIGURA

    %% ========================================================
 
    figure('Color','w','Name',nombre,'Position',[100 100 1000 750]);
 
    tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
 
    %% TX
 
    nexttile;
 
    plot(I_TX,Q_TX,'.','MarkerSize',5);
 
    grid on;

    box on;

    axis equal;
 
    xlabel('Componente I');

    ylabel('Componente Q');
 
    title('Salida del transmisor');
 
    ajustar_ejes(I_TX,Q_TX);
 
    %% ADC
 
    nexttile;
 
    plot(I_ADC,Q_ADC,'.','MarkerSize',4);
 
    grid on;

    box on;

    axis equal;
 
    xlabel('Componente I');

    ylabel('Componente Q');
 
    title('Salida del ADC');
 
    ajustar_ejes(I_ADC,Q_ADC);
 
    %% FILTRO ADAPTADO
 
    nexttile;
 
    plot(I_FILTRO,Q_FILTRO,'.','MarkerSize',4);
 
    grid on;

    box on;

    axis equal;
 
    xlabel('Componente I');

    ylabel('Componente Q');
 
    title('Salida del filtro adaptado');
 
    ajustar_ejes(I_FILTRO,Q_FILTRO);
 
    %% GARDNER
 
    nexttile;
 
    plot(I_GARDNER,Q_GARDNER,'.','MarkerSize',8);
 
    grid on;

    box on;

    axis equal;
 
    xlabel('Componente I');

    ylabel('Componente Q');
 
    title('Salida de Gardner');
 
    ajustar_ejes(I_GARDNER,Q_GARDNER);
 
    %% TITULO GENERAL
 
    sgtitle(nombre,'FontWeight','bold','FontSize',14);
 
end
 
 
%% ============================================================

% FUNCIONES

%% ============================================================
 
 
%% LEER TX - DATOS DE 16 BITS
 
function [I,Q] = load16(file,cI,cQ)
 
    fid = fopen(file);
 
    if fid < 0

        error('No encuentro %s',file);

    end
 
    C = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f%*[^\n]','Delimiter',',','HeaderLines',2);
 
    fclose(fid);
 
    I = C{cI};

    Q = C{cQ};
 
end
 
 
%% LEER ADC Y FILTRO - PALABRAS DE 64 BITS
 
function [I,Q] = load64(file,cI,cQ)
 
    fid = fopen(file);
 
    if fid < 0

        error('No encuentro %s',file);

    end
 
    C = textscan(fid,'%f%f%f%d64%d64%*[^\n]','Delimiter',',','HeaderLines',2);
 
    fclose(fid);
 
    I = unpack64(C{cI});

    Q = unpack64(C{cQ});
 
end
 
 
%% DESEMPAQUETAR 64 BITS EN 4 MUESTRAS DE 16 BITS
 
function s = unpack64(col)
 
    u = typecast(int64(col(:)),'uint64');
 
    s = zeros(numel(u)*4,1);
 
    for k = 0:3
 
        lane = double(bitand(bitshift(u,-16*k),uint64(65535)));
 
        lane(lane >= 32768) = lane(lane >= 32768) - 65536;
 
        s(k+1:4:end) = lane;
 
    end
 
end
 
 
%% LEER GARDNER
 
function [I,Q,valid] = loadGardner(file)
 
    fid = fopen(file);
 
    if fid < 0

        error('No encuentro %s',file);

    end
 
    C = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f%*[^\n]','Delimiter',',','HeaderLines',2);
 
    fclose(fid);
 
    I = C{4};

    validI = C{5};
 
    Q = C{8};

    validQ = C{9};
 
    valid = (validI == 1) & (validQ == 1);
 
end
 
 
%% AJUSTAR EJES DE FORMA SIMETRICA
 
function ajustar_ejes(I,Q)
 
    I = double(I(:));

    Q = double(Q(:));
 
    valores = abs([I;Q]);
 
    valores = valores(isfinite(valores));
 
    if isempty(valores)

        return;

    end
 
    limite = max(valores);
 
    if limite == 0

        limite = 1;

    end
 
    limite = limite * 1.05;
 
    xlim([-limite limite]);

    ylim([-limite limite]);
 
end
 
