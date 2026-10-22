# TFG - Módem QPSK en la RFSoC 4x2

Código de mi Trabajo Fin de Grado: un módem QPSK implementado en la FPGA de la placa RFSoC 4x2 (Zynq UltraScale+ RFSoC XCZU48DR). El transmisor y el receptor están en la lógica programable y se prueban en lazo, sacando la señal por el DAC y volviéndola a meter por el ADC con un cable.

Hay dos versiones:

- **Banda base:** I y Q salen por dos DAC distintos y vuelven por dos ADC, con dos cables. Convertidores a 1 GSPS.
- **Portadora de 1 GHz:** el RF Data Converter sube I/Q a 1 GHz con su NCO y lo vuelve a bajar en el ADC, con un solo cable. Convertidores a 4 GSPS. En las pruebas en placa el enlace da BER 0.

El resto de la cadena es igual en las dos: PRBS-15 o secuencia fija → modulador QPSK con filtro RRC → DAC → ADC → filtro adaptado → sincronismo de símbolo (Gardner) → lazo de Costas → decisión → medidor de BER.

## Carpetas

- `rtl/common/`: código común a las dos versiones (transmisor, receptor, generadores de datos y medidor de BER).
- `rtl/baseband/` y `rtl/carrier_1ghz/`: lo que cambia entre versiones. El paquete `qpsk_coef_pkg.sv` (amplitud `A_SYM` de 4000 en banda base y de 10000 a 1 GHz) y, en la de 1 GHz, `iq_pack.v`, que junta I y Q en una sola palabra para el DAC.
- `sim/`: testbenches.
- `vivado/`: block design de cada versión y restricciones (`mts.xdc`).
- `model/`: modelo en Python que usé para validar el algoritmo y sacar los coeficientes del filtro RRC.
- `matlab/`: scripts para analizar las capturas del ILA.
- `pynq/`: notebook para manejar la placa.
- `docs/`: memoria del TFG y guía del paso a 1 GHz.

## Cómo usarlo

Está hecho con Vivado 2024.1 (part `xczu48dr-ffvg1517-2-e`). Para regenerar el proyecto hay que crear un proyecto nuevo, añadir `rtl/common` y la carpeta de la versión, añadir `mts.xdc` y cargar el block design de `vivado/`. Después se crea el wrapper y se genera el bitstream.

En la placa uso PYNQ: se ponen los relojes a 500 MHz (`xrfclk.set_ref_clks(500.0, 500.0)`), se carga el overlay y se leen los contadores del medidor de BER en `0x80010000`. El selector entre PRBS y secuencia fija es el GPIO de `0x80070000`.

## Notas

- `Generador_PRBS.v` contiene el módulo `PRBS_core`.
- A 1 GHz el NCO del DAC va a +1 GHz y el del ADC a −1 GHz.
- El diseño parte del proyecto [RFSoC-MTS](https://github.com/Xilinx/RFSoC-MTS) de AMD/Xilinx, del que vienen el `mts.xdc` y la parte de relojes del block design.

Rubén Mata Alonso - Universidad Autonoma de Madrid - Grado en Ingeniería de Tecnologías y Servicios de Telecomunicación
