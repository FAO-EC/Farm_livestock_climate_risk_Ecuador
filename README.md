



GANADERÍA CLIMÁTICAMENTE INTELIGENTE
INTEGRANDO LA REVERSIÓN DE LA DEGRADACIÓN DE TIERRAS Y REDUCIENDO LOS RIESGOS DE DESERTIFICACIÓN EN PROVINCIAS VULNERABLES	 



DOCUMENTO TÉCNICO


HERRAMIENTA DE CUANTIFICACIÓN DE RIESGO CLIMÁTICO EN SISTEMAS GANADEROS

Descripción del modelo y guía de usuario
(versión R)





Quito, Ecuador
Mayo, 2020




Proyecto: GCP/ECU/085/GFF – GCPECU/092/SCF
Ganadería Climáticamente Inteligente
Integrando la Reversión de Degradación de Tierras y Reducción del Riesgo de Desertificación en Provincias Vulnerables	 


Ejecutado por el Ministerio del Ambiente (MAE), Ministerio de Agricultura, Ganadería, Acuacultura y Pesca (MAGAP), con el apoyo técnico de la Organización de las Naciones Unidad para la Agricultura y la Alimentación (FAO) y el financiamiento del Fondo Mundial para el Medio Ambiente (GEF). 




Documento Técnico: herramienta de cuantificación de riesgo climático en sistemas ganaderos.
Elaborado por:
Armando Rivera Moncada (Técnico SIG- Proyecto GCI)
Revisado por:
Juan Merino (Coordinador Nacional del Proyecto GCI)
Jonathan Torres Celi (Técnico en Adaptación del Proyecto GCI)
Pamela Sangoluisa (Especialista en Mitigación del Proyecto GCI)



Quito, mayo de 2019


CONTENIDO
CONTENIDO	3
1.	INTRODUCCIÓN	4
2.	ESTRUCTURA DEL MODELO	6
3.	DATOS DE ENTRADA	9
3.1.	Datos de la Finca: input_data.csv	9
3.1.1.	Datos generales	9
3.1.2.	Datos del hato: Número de animales por categoría	9
3.1.3.	Datos de áreas: distribución de áreas productivas o de conservación	10
3.1.4.	Datos del manejo de pastos	10
3.1.5.	Datos de ataques de animales silvestres, acceso a fuentes de agua	11
3.1.6.	Datos de escases o exceso de agua	11
3.1.7.	Datos de cercas vivas y cultivos asociados a la ganadería	12
3.1.8.	Datos de herramientas de planificación en la finca	12
3.1.9.	Datos de la infraestructura de la finca	13
3.1.10.	Datos de acceso a fuentes de inversión	13
3.1.11.	Sistema productivo y acceso a información del clima	13
4.	PROCESAMIENTO DE DATOS	14
4.1.	Consideraciones de la Homologación de los Datos de Finca con los Datos Parroquiales	14
4.2.	Correr el Modelo	16
5.	RESULTADOS	17
6.	HERRAMIENTA WEB	17
7.	BIBLIOGRAFÍA	18
8.	ANEXOS	19


ACRÓNIMOS

GEI	Gases de efecto invernadero
GCI	Ganadería Climáticamente Inteligente
FAO	Organización de las Naciones Unidas para la Alimentación y Agricultura
SIG	Sistemas de Información Geográfica




 
INTRODUCCIÓN
El proyecto Ganadería Climáticamente Inteligente (GCI) es una iniciativa implementada en conjunto por el Ministerio de Agricultura y Ganadería (MAG), el Ministerio del Ambiente y Agua (MAEA) y la Organización de las Naciones Unidas para la Alimentación y la Agricultura (FAO), con el financiamiento del Fondo Mundial para el Medio Ambiente (GEF). El objetivo del proyecto es reducir la degradación de la tierra e incrementar la capacidad de adaptación al cambio climático y de reducción de emisiones de gases de efecto invernadero (GEI), a través de la implementación de políticas intersectoriales y técnicas de ganadería sostenible, con particular atención en las provincias vulnerables. Entre sus cuatro componentes se destaca la implementación de estrategias de transferencia, difusión e implementación de tecnologías para el manejo ganadero climáticamente inteligente y el monitoreo de las emisiones de GEI y de la capacidad adaptativa en el sector ganadero.

Específicamente en el eje de Adaptación del proyecto GCI, se generó un análisis de riesgo climático en las siete provincias de intervención (Guayas, Manabí, Santa Elena, Imbabura, Loja, Napo y Morona Santiago), utilizando a la parroquia como unidad de análisis (MAG, MAE, FAO, 2019). La metodología utilizada se basó en las directrices del IPCC (AR5) para definir riesgo climático como la integración de tres factores: amenaza climática, exposición y vulnerabilidad de un sistema (este último determinado por la sensibilidad y capacidad adaptativa) (IPCC, 2014). 

El proceso de evaluación en las siete provincias se realizó considerando tres dimensiones con su respectiva exposición: ambiental (cuyo elemento expuesto es el porcentaje de área de pastos), socioeconómico (que considera la tenencia ganadera como elemento expuesto) y gobernanza (índice de asociatividad como elemento expuesto). La vulnerabilidad se analizó con base al análisis de 16 indicadores ambientales y socioeconómicas relacionados a la actividad ganadera para definir sensibilidad, y 18 indicadores para capacidad adaptativa. Adicionalmente, se consideraron tres dimensiones para el estudio:. Todo ello evaluado para cuatro amenazas: sequías, lluvias intensas, olas de calor y heladas. La fórmula utilizada para el cálculo de riesgo climático es:

Riesgo Climático= Amenaza*Exposición*Vulnerabilidad

Vulnerabilidad=  Sensibilidad/(Capacidad adaptativa)

El estudio muestra resultados a nivel parroquial. Sin embargo, el proyecto GCI adaptó la metodología a nivel de finca para evaluar la capacidad adaptativa y riesgo climático, mediante un proceso de homologación de indicadores. El proceso consistió en analizar cada uno de los indicadores que conforman exposición, sensibilidad y capacidad adaptativa e identificar indicadores que sean medibles en una finca y que puedan reemplazar los indicadores parroquiales. Por ejemplo para el caso de exposición ambiental parroquial, se utiliza porcentaje de pastos en la parroquia, y en el caso de la finca se homologó con el dato de porcentaje de pastos en la finca. La sección 3.1 muestra cada uno de los indicadores que fueron homologadas. Es importante mencionar que aquellos indicadores que no pudieron ser homologadas a nivel de finca, conservan los valores parroquiales.

Para probar la funcionalidad y robustez metodológica, así como cuantificar el impacto en el eje de adaptación al cambio climático dado por la implementación de buenas prácticas ganaderas, durante tres años fueron monitoreadas 165 fincas piloto, ubicadas en las siete provincias de intervención, las cuales sirvieron como fuente de información continua, sobre datos productivos, reproductivos y de manejo. 

Para facilitar una mayor comprensión de este modelo, se debe considerar la siguiente terminología: (I) Indicadores, corresponden a los datos crudos por parroquias; (II) Índices (sensibilidad, capacidad adaptativa, exposición, amenazas), son el resultado de la agregación aritmética ponderada de los indicadores y sus pesos; y, (III) Factor (vulnerabilidad, riesgo climático), resultan de la integración matemática entre los índices.



ESTRUCTURA DEL MODELO
  
El modelo descrito por MAG, MAE y FAO (2019) permite evaluar el riesgo climático parroquial, tomando una provincia como universo estadístico. De esta manera, permite observar cuales son las parroquias que tienen un mayor riesgo dentro de una provincia. El trabajo desarrollado analizó datos de las siete provincias de intervención del proyecto GCI. El modelo evalúa la interacción de cuatro índices (amenaza climática, exposición, sensibilidad y capacidad adaptativa. La figura 1 muestra el proceso de cálculo de cada uno de los índices.

El modelo consideró cuatro amenazas climáticas, construidas con diferentes indicadores climáticas. Estas se describen en el cuadro 1:

Tabla 1: Descripción de los indicadores consideradas para la construcción de las amenazas climáticas

Amenaza climática	Indicadores considerados	Descripción
Sequías	CDD	Mayor número de días secos consecutivos en un año
	CDD_M	Mayor número de días secos consecutivos en un mes
	SPI	Índice de Precipitación Estandarizado mensual
Lluvias intensas	R95p	Número de días en un año con lluvia mayor al percentil 95 para los días húmedos -Prec. > 1,0mm
	R99p	Número de días en un año con lluvia mayor al percentil 99 para los días húmedos -Prec. > 1,0mm
	NCDR95p	Mayor número de días consecutivos en un mes con precipitaciones mayores al percentil 95
	NCDR99p	Mayor número de días consecutivos en un mes con precipitaciones mayores al percentil 99
	CDR90p	Mayor número de días consecutivos en un mes con precipitaciones mayores al percentil 90
	PRCPTOT_M	Precipitación total mensual
Heladas	FD0	Número de días con temperatura mínima inferior a 0°C en un año
	TN3	Número de días en un mes con temperatura mínima inferior a 3°C - helada agrometeorológica10
Olas de calor	Tx90p	Porcentaje de días con temperatura máxima mayor al Percentil 90 - Días calientes en un año
	SU25	Mayor número de días consecutivos con temperatura superior a 25°C -estrés térmico para el ganado en un año
	TX25	Mayor número de días consecutivos en un mes con temperatura superior a 25°C -estrés térmico para el ganado
	TMedMean	Temperatura promedio mensual

Todos los indicadores fueron transformadas a datos parroquiales, que es la unidad de análisis del modelo. 

Para la exposición, se consideraron tres dimensiones (ambiental, socioeconómica y gobernanza). En el ejercicio del análisis a nivel de finca se consideraron las dos primeras dimensiones, ya que es difícil determinar el nivel de gobernanza de una finca. La dimensión ambiental toma como elemento expuesto al porcentaje de pastos de las parroquias. La dimensión socioeconómica toma la tenencia ganadera (número de animales por productor) de cada una de las parroquias.

Adicionalmente, se consideraron 16 indicadores para calcular el índice de sensibilidad: carga animal, capacidad de uso de la tierra, deforestación 2014-2016, conflicto gente fauna, índice de heladas CIFEN, degradación del suelo, porcentaje inundable, pobreza por consumo, tasa de dependencia por edad, analfabetismo funcional, nivel de organización, población migrante por sexo, porcentaje de la población dedicada a agricultura y ganadería, déficit habitacional cualitativo, déficit de servicios residenciales básicos, y capacidad de gestión. 

Para el cálculo del índice de capacidad adaptativa se consideraron 18 indicadores: porcentaje de presencia de socio bosque, cobertura de vegetación natural, infraestructura multipropósito, índice de red hídrica, cobertura de riesgo estatal, velocidad de infiltración, pendiente promedio, índice de red vial, herramientas de planificación, sistemas productivos pecuarios, volumen de crédito, disponibilidad de pronóstico del clima, cobertura móvil por parroquia, existencia de camales, existencia de CAB, existencia de CAL, existencia de red de monitoreo de hidrometereología y UMVMAG.

Cada uno de los indicadores de sensibilidad y capacidad adaptativa fueron analizadas individualmente y considerada por cada una de las dimensiones y amenaza climática. Por ejemplo para la sensibilidad de la dimensión ambiental en la amenaza sequía se consideraron 4 indicadores (degradación del suelo, capacidad de uso de la tierra, carga animal y deforestación 2014-2016), y para la capacidad adaptativa en la misma dimensión y amenaza se consideraron 5 indicadores (infraestructura multipropósito, cobertura de riesgo estatal, cobertura de vegetación natural, índice de red hídrica y porcentaje de presencia de socio bosque). 

La descripción de cada indicador se puede encontrar en el documento del estudio de riesgo climático MAG, MAE y FAO (2019). El proceso de tratamiento de los indicadores para el cálculo de cada índice (capacidad adaptativa o sensibilidad) se describe a continuación:

	El universo de datos es la parroquia, es decir, que se comparan los datos de las parroquias que conforman una provincia.
	Seleccionamos las provincias de una provincia
	Se normalizan los datos de los indicadores. 
	Se asignan pesos a cada indicador basándose en la desviación estándar.
	Se calcula el índice (sensibilidad y capacidad adaptativa ) multiplicando cada indicador por su peso.
	Se normalizan los datos de los índices calculados.
	Se categorizan los datos de acuerdo con una distribución beta en 5 niveles: 1 – muy bajo, 2 – bajo, 3 – moderado, 4 – alto,  5 – muy alto.
	Con los índices se calcula el riesgo climático parroquial.

El proceso de cálculo a nivel de finca consiste en un levantamiento y construcción de 20  indicadores de distribución y manejo de la finca: carga animal finca, área de la finca, área de plantaciones forestales finca, área bajo conservación finca, área de pastos finca, área pastos en sistema silvopastoril finca, manejo de potreros finca, ataques de animales silvestres finca, acceso a fuentes agua finca, sistemas riego finca, cultivos asociados finca, drenajes finca, cercas vivas finca, planificación de finca, calendario reproductivo finca, plan de vacunación finca, infraestructura finca, crédito de la finca, sistema productivo finca y acceso a información del clima finca. 

Mediante un proceso automático, se extraen los datos de la}os indicadores de la parroquia a la cual pertenece la finca. A continuación se realiza un proceso de homologación de indicadores. Por ejemplo la carga animal parroquial es reemplazada por la carga animal de la finca, la exposición ambiental que está construida con el porcentaje de pastos de la parroquia es reemplazada por el porcentaje de pastos de la finca. El proceso de homologación se describe en la sección 3.1. El siguiente paso es normalizar los indicadores de la finca con los datos parroquiales. A continuación se calcula los índices multiplicando el dato de los indicadores por el peso calculado en el análisis parroquial. 
Se insertan los nuevos datos como si fuera una nueva parroquia en la provincia. Se categorizan en los cinco niveles y se procede a calcular el riesgo climático.

Este proceso se automatizó con el software descrito en este documento. Los datos de cada indicador a nivel de parroquia se encuentran en el directorio “input”, en el archivo “actual.csv”. 

DATOS DE ENTRADA

Se generó una matriz de entrada “input_data.xls”, la cual recopila datos de los indicadores de distribución y manejo de la finca. Los datos requeridos en esta matriz fueron analizados por el equipo técnico del proyecto GCI, buscando evaluar el impacto de la implementación de buenas prácticas ganaderas, que fueron promovidas por el proyecto en Escuelas de Campo con productores/as. La homologación de indicadores (respecto del estudio de riesgo climático a nivel parroquial) y su interacción para el cálculo a nivel de finca, se describen en este documento.

Los datos ingresados deben ser el promedio de un año calendario. 

Datos de la Finca: input_data.csv
Datos generales
Indicador	Descripción
fecha	Año de evaluación. Se puede incluir una fecha específica o período
finca	Nombre de la finca
parroquia_id	ID de la parroquia a la que pertenece la finca. Se puede observar un listado de las parroquias en el anexo 1

Datos del hato: Número de animales por categoría
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
vacas	Número de hembras adultas (mayores a 2 años) que se tuvo en el año, incluidas en producción y secas*	Carga animal
	Ambiental
Socioeconómica	Exp. socioeconómica
Sensibilidad
vacas_produccion	Número de hembras adultas que estén produciendo leche*	Carga animal	Ambiental
Socioeconómica	Exp. socioeconómica
Sensibilidad
vaconas	Número de hembras entre 1 y 2 años	Carga animal	Ambiental
Socioeconómica	Exp. socioeconómica
Sensibilidad
terneras	Número de hembras menores a 1 año	Carga animal	Ambiental
Socioeconómica	Exp. socioeconómica
Sensibilidad
toros	Número de machos adultos (mayores a 2 años)	Carga animal	Ambiental
Socioeconómica	Exp. socioeconómica
Sensibilidad
toretes	Número de machos entre 1 y 2 años	Carga animal	Ambiental
Socioeconómica	Exp. socioeconómica
Sensibilidad
terneros	Número de machos menores a 1 año	Carga animal	Ambiental
Socioeconómica	Exp. socioeconómica
Sensibilidad
* El número promedio total animales que se tuvo durante el año de evaluación, sin incluir animales que se vendieron, descartaron o que murieron.

Carga animal = UBAs / (área de pastos + área de cultivos asociados)
UBAs = vacas + (vaconas*0.7) + (terneras*0.6) + (toros*1.3) + (toretes*0.7) + (terneros*0.6)
 
Datos de áreas: distribución de áreas productivas o de conservación
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
superficie_finca
_ha	Área total de la finca en hectáreas	Porcentaje de presencia de socio bosque, cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
superficie_
plantaciones
_forestales_ha	Área con plantaciones forestales de la finca en hectáreas 	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
superficie_
conservacion
_ha	Área bajo conservación de la finca en hectáreas 	Porcentaje de presencia de socio bosque, cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
superficie_
pastos_ha	Área con pastos de la finca en hectáreas 	Carga animal	Ambiental
Socioeconómica	Exp. socioeconómica
Sensibilidad
sistema_
silvopastoril
_sino*	Opción de manejo de pastos en sistemas silvopastoriles	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
superficie_
pastos_con
_silvopastoril_ha	Área de los pastos en sistemas silvopastoriles. Si la anterior opción es NO, este indicador debe ser cero.	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
*Escribir una sola opción: SI, NO (en mayúsculas)

Datos del manejo de pastos
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
siembra_
resiembra_
pastos_sino*	Opción de sembrar o resembrar pastos	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
fertiliza_pastos
_sino*	Opción de fertilizar los pastos	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
division_
potreros_
pastoreo_
rotacional_sino*	Opción de realizar división de potreros	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
superficie_pastos
_manejados_ha	Área de los pastos en hectáreas, en los que se realizan alguna de las actividades anteriores.	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
*Escribir una sola opción: SI, NO (en mayúsculas)
 
Datos de ataques de animales silvestres, acceso a fuentes de agua
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
ataques_animales
_silvestres_sino*	Opción de sufrir el ganado de ataques de animales silvestres 	Conflicto gente fauna	Socioeconómica	Sensibilidad
vertientes_
naturales_sino*	Opción de tener acceso a vertientes naturales en la finca	Índice de red hídrica	Ambiental
Socioeconómica	Capacidad adaptativa
ojos_agua_sino*	Opción de tener acceso a ojos de agua en la finca	Índice de red hídrica	Ambiental
Socioeconómica	Capacidad adaptativa
acceso_quebradas
_sino*	Opción de tener acceso a quebradas en la finca	Índice de red hídrica	Ambiental
Socioeconómica	Capacidad adaptativa
acceso_rios_sino*	Opción de tener acceso a ríos en la finca	Índice de red hídrica	Ambiental
Socioeconómica	Capacidad adaptativa
agua_subterranea
_sino*	Opción de tener acceso a agua subterránea en la finca	Índice de red hídrica	Ambiental
Socioeconómica	Capacidad adaptativa
*Escribir una sola opción: SI, NO (en mayúsculas)

Datos de escases o exceso de agua 
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
escases_agua
_sino*	Opción de sufrir de escasez de agua en la finca	infraestructura multipropósito	Ambiental	Capacidad adaptativa
Albarradas
_reservorios
_sino*	Opción de tener albarradas o reservorios en la finca	infraestructura multipropósito	Ambiental	Capacidad adaptativa
agua_entubada
_riego_sino*	Opción de disponer de agua entubada en la finca	infraestructura multipropósito	Ambiental	Capacidad adaptativa
sistema_riego
_sino*	Opción de tener un sistema de riesgo en la finca	infraestructura multipropósito	Ambiental	Capacidad adaptativa
superficie_riego
_ha	Área de pastos o cultivos asociados a la ganadería en hectáreas, que se encuentran bajo sistema de riego	Cobertura de riego	Ambiental
Socioeconómica	Capacidad adaptativa
Inundaciones
_sino*	Opción de sufrir de inundaciones en la finca	infraestructura multipropósito	Ambiental	Capacidad adaptativa
drenajes_sino*	Opción de tener drenajes en la finca	infraestructura multipropósito	Ambiental	Capacidad adaptativa
*Escribir una sola opción: SI, NO (en mayúsculas)
 
Datos de cercas vivas y cultivos asociados a la ganadería
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
Porcentaje
_linderos
_cercas_vivas_%	Porcentaje de las cercas y divisiones de potreros que tienen cercas vivas	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
cultivos_
asociados_sino*	Opción de tener cultivos específicos para alimentar al ganado	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
cultivos_
asociados_ha	Área de cultivos asociados a la ganadería en hectáreas	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
Escases
_alimento**	Opción de sufrir de escasez de alimento para el ganado	Cobertura de vegetación natural	Ambiental
Socioeconómica	Capacidad adaptativa
*Escribir una sola opción: “SI”, “NO” (en mayúsculas)
**Escribir una sola opción: “SI”, “NO”, “SI, Y HACE CONSERVACION DE FORRAJES” (en mayúsculas, tal como se muestra, sin las comillas)

Datos de herramientas de planificación en la finca
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
planificación
_forrajera*	Opción de disponer de una planificación de forrajes en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
Calendario
_reproductivo*	Opción de disponer de calendario de reproducción del ganado	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
plan_vacunacion
_desparasitacion*	Opción de disponer de un plan de vacunación del ganado	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
*Escribir una sola opción: “NINGUNO”, “ELABORADO”, “EN EJECUCION” (en mayúsculas, tal como se muestra, sin las comillas)
 
Datos de la infraestructura de la finca
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
corral_sino*	Opción de disponer de corral en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
manga_sino*	Opción de disponer de manga en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
caseta_ordeno
_sino*	Opción de disponer de caseta para el ordeño en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
comedero_sino*	Opción de disponer de comederos en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
pesebrera_cuna
_sino*	Opción de disponer de pesebreras o cunas en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
bodega_sino*	Opción de disponer de bodega para insumos en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
alzadero_sino*	Opción de disponer de alzaderos en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
bebederos_sino*	Opción de disponer de bebederos en la finca	Herramientas de cambio climático	Socioeconómica	Capacidad adaptativa
*Escribir una sola opción: SI, NO (en mayúsculas)

Datos de acceso a fuentes de inversión 
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
credito_acceso
_sino*	Opción de poder acceder a un crédito para la finca	Volumen de crédito	Socioeconómica	Capacidad adaptativa
credito_usd	Monto máximo en USD del crédito al que puede acceder 	Volumen de crédito	Socioeconómica	Capacidad adaptativa
monto_inversion
_fuera_del_credito
_usd	Monto máximo en USD fuera del crédito del que dispone para invertir en la finca (ahorros, ingresos extras, etc.)	Volumen de crédito	Socioeconómica	Capacidad adaptativa
*Escribir una sola opción: SI, NO (en mayúsculas)

Sistema productivo y acceso a información del clima
Indicador	Descripción	Indicador homologado	Dimensión	Componente del Riesgo Climático
Sistema
_productivo**	Opción del tipo de sistema productivo de la finca	Sistema productivo pecuario	Socioeconómica	Capacidad adaptativa
uso_informacion
_clima*	Opción de tener tener acceso a información del clima	Red de monitoreo de hidrometereología	Socioeconómica	Capacidad adaptativa
*Escribir una sola opción: SI, NO (en mayúsculas)
**Escribir una sola opción: MARGINAL, MERCANTIL, COMBINADO, EMPRESARIAL (en mayúsculas tal como se muestran)

Los sistemas se basan en la metodología de valoración de tierras rurales (MAGAP & PRAT, 2008): Marginal (prácticas de manejo tradicionales, principal fuente de ingresos no proviene de la finca, genera pocos excedentes para la venta de productos); Mercantil (los productos generados en la finca son comercializados constantemente, la principal fuerza de trabajo en la finca es familiar, bajo en nivel de tecnificación); Combinado (semi-tecnificado, la principal fuerza de trabajo en la finca es asalariada, los productos generados en la finca son comercializados constantemente); y, Empresarial (altamente tecnificado, la principal fuerza de trabajo en la finca es permanente y asalariada, producción destinada a la agroindustria y mercado de exportación) 

PROCESAMIENTO DE DATOS
Para el procesamiento de los resultados, se generó un script “script_riesgo_actual.R” en R programming, que incluye todos los algoritmos desarrollados para la automatización de cálculo de la capacidad adaptativa, sensibilidad y riesgo climático. El software incluye varias funciones para normalizar datos, para el cálculo de los pesos en base a la varianza y/o desviación estándar, cálculo de sensibilidad y capacidad adaptativa, y una función para categorización de datos a través de la distribución beta. El desarrollo del script contiene comentarios específicos que permiten una lectura fácil y ágil.

Consideraciones de la Homologación de los Datos de Finca con los Datos Parroquiales
El proceso de homologación de los indicadores de la finca con los indicadores parroquiales conlleva varios análisis, ya que un indicador parroquial puede estar conformado por varios indicadores de la finca. Adicionalmente, las unidades de cada indicador fueron homologadas también. La tabla 2 muestra una descripción de todas las consideraciones a tener en cuenta en este proceso.

Tabla 2: Consideraciones del proceso de homologación de indicadores a nivel de finca con los indicadores parroquiales.
Indicador parroquial	Observación
Herramientas de planificación para el Cambio Climático	Tiene un valor de cero a uno. Si existen herramientas en la parroquia, se le asigna un valor de 1, caso contrario cero. Para la homologación, se asignaron los siguientes pesos de los indicadores de la finca:

0.28 está asignado a los 8 indicadores de infraestructura de la finca (ver sección 1.3.1.9). Es decir, que cada indicador de esta sección aporta con 3.5% si tiene la opción “SI”.

0.72 está asignado a los 3 indicadores de herramientas de planificación (ver sección 1.3.1.8).  Cada indicador aporta con 0.24 cuando tiene la opción “EN EJECUCION”. Si tiene la opción “ELABORADO” se le asigna 0.12 y si tiene la opción “NINGUNO” se le asigna un valor de cero.

Volumen de crédito	Tiene un valor en USD y representa el crédito acumulado al que accedieron las parroquias para temas ganaderos. Al ser valores muy altos y no comparables con un crédito de una finca, se elaboró una matriz con datos de créditos al que han accedido las fincas piloto del proyecto GCI (matriz datoscredito.csv en el directorio input). Con estos datos se realiza la normalización de los datos de crédito de la finca, la cual está compuesta por la sumatoria de los datos de los indicadores "credito_usd" y "monto_inversion_fuera_del_credito_usd" (ver sección 3.1.10)

Sistema productivo	Tiene un valor de 1 a 4, siendo 1 - MARGINAL, 2 - MERCANTIL, 3 - COMBINADO y 4 - EMPRESARIAL. Estos valores se asignan al indicador de “Sistema productivo” que se define en la finca.

Red de monitoreo de hidrometereología	Tiene un valor de cero a uno. Cuando existe la red se asigna un valor de uno, caso contrario cero. Este mismo valor se da al indicador de “Uso de Información del Clima” que se levanta en la finca.



Cobertura de riego	Representa el porcentaje de la parroquia que se encuentra bajo riego. Para la homologación, se calcula el porcentaje de la finca que se encuentra bajo riego, mediante la siguiente fórmula:

% riego = superficie riego / (superficie pastos + superficie cultivos asociados) * 100

Infraestructura multipropósito	Tiene un valor de cero a uno, asignando uno cuando existe la infraestructura. Para el proceso de homologación, se tomaron los siguientes indicadores a nivel de finca:

Para la amenaza sequía, si no tiene escasez de agua (ver sección 1.3.1.6), se le asigna uno, caso contrario, se le asigna:
	Si tiene agua entubada se le asigna 0.333 
	Si tiene reservorio se le asigna 0.333
	Si tiene sistema de riego se le asigna 0.333

Para la amenaza lluvias intensas, si no tiene inundaciones (ver sección 1.3.1.6), se le asigna uno, caso contrario, se le asigna 1 si tiene drenajes.

Índice de red hídrica	Para la homologación del indicador parroquial, se tomaron los indicadores parroquiales de acceso a fuentes de agua (ver sección 1.3.1.5). Si tiene acceso a cualquier fuente de agua, se asigna el 100 % del valor parroquial.

Cobertura natural	Representa el porcentaje de la parroquia que tiene cobertura natural. Para la homologación se tomaron varios indicadores a nivel de finca:

Cobertura natural = (superficie conservación + superficie plantaciones forestales + superficie silvopastoril + superficie cercas vivas +  (superficie pastos manejo * pasto_manejo_coeficiente) +  (superficie cultivos asociados * cultivo_asociados_ganado_coeficiente)) / superficie_finca_ha * 100

pasto_manejo_coeficiente está dado por los 3 indicadores de manejo de pastos (ver sección 1.3.1.4):
	Si siembra o resiembra pastos se asigna 0.333
	Si fertiliza los pastos se asigna 0.333
	Si divide potreros se asigna 0.333

cultivo_asociados_ganado_coeficiente está calculado por 2 indicadores:
	Si siembra cultivos asociados se le asigna 0.5
	Si no tiene falta de alimento o si hace conservación de forrajes se le asigna 0.5

superficie_cercas_vivas = ((((2.528*(superficie finca))+ 1.9848) * 0.02) * (porcentaje cercas vivas / 100))

Conflicto gente fauna	Tiene un valor de uno cuando se ha reportado este tipo de ataques al ganado. Para la homologación se asigna uno a la pregunta de ataques de animales silvestres en la finca (ver sección 3.1.5).

Porcentaje de presencia de sociobosque	Representa el porcentaje de la parroquia en la cual está presente los bosques reportados en este programa de gobierno. Para la homologación se toman los siguientes indicadores en finca:    
    
presencia sociobosque = superficie conservación / superficie finca * 100



 
Correr el Modelo
El script de programación está realizado en R programing y requiere del software R para su uso. Adicionalmente se recomienda utilizar RStudio para un fácil procesamiento del script. Las pruebas fueron realizadas utilizando la versión 3.6.1 de R y la versión 1.2.1335 de RStudio.

La carpeta que contiene el script debe contener el archivo XLSX de los datos de entrada, tal como se muestra en la Figura 1.

 
Figura 2: componentes del script de emisiones

Ver sección 3 para conocer la manera de gestionar los datos de entrada. Una vez completos los archivos de entrada continuamos con el siguiente procedimiento:

	Abrir el archivo script_riesgo_actual.R en RStudio
	Seleccionar todas las líneas de código
	Presionar el botón RUN
	Se genera un directorio con la fecha y hora de procesamiento, con los resultados por cada finca analizada.
 
RESULTADOS 
El script genera un directorio con la fecha y hora en el que se procesó el cálculo. Dentro de este directorio se genera una matriz por cada finca analizada (ver cuadro 1). La matriz incluye los resultados de la capacidad adaptativa, sensibilidad, vulnerabilidad y riesgo climático para cuatro amenazas (sequía, heladas, lluvias intensas y olas de calor).

Cuadro 1: Matriz de salida del cálculo de riesgo climático
	finca	finca 1-5	parroquia	parroquia 1-5
capacidad_adaptativa_ambiental_sequia	0.44	5	0.10	4
sensibilidad_ambiental_sequia	0.62	3	0.55	3
vulnerabilidad_ambiental_sequia	0.01	3	0.02	3
riesgo_climatico_ambiental_sequia	0.00	1	0.00	1
capacidad_adaptativa_ambiental_heladas	0.77	5	0.38	5
sensibilidad_ambiental_heladas	0.00	1	0.00	1
vulnerabilidad_ambiental_heladas	0.00	1	0.00	1
riesgo_climatico_ambiental_heladas	0.00	1	0.00	1
capacidad_adaptativa_ambiental_lluvias	0.74	5	0.14	4
sensibilidad_ambiental_lluvias	0.53	3	0.48	3
vulnerabilidad_ambiental_lluvias	0.00	1	0.00	2
riesgo_climatico_ambiental_lluvias	0.00	1	0.15	4
capacidad_adaptativa_socioeconomico_sequia	0.34	4	0.31	4
sensibilidad_socioeconomico_sequia	0.57	4	0.54	3
vulnerabilidad_socioeconomico_sequia	0.15	3	0.16	3
riesgo_climatico_socioeconomico_sequia	0.00	1	0.00	1
capacidad_adaptativa_socioeconomico_lluvias	0.51	4	0.43	4
sensibilidad_socioeconomico_lluvias	0.54	3	0.52	3
vulnerabilidad_socioeconomico_lluvias	0.04	1	0.05	1
riesgo_climatico_socioeconomico_lluvias	0.35	3	0.40	3
capacidad_adaptativa_socioeconomico_olasdecalor	0.30	4	0.49	4
sensibilidad_socioeconomico_olasdecalor	0.84	4	0.75	3
vulnerabilidad_socioeconomico_olasdecalor	0.29	3	0.14	3
riesgo_climatico_socioeconomico_olasdecalor	0.79	4	0.67	4

Las columnas en azul representan los resultados de la finca (la columna finca es el dato aritmético, y la columna finca 1 – 5 muestra el resultado categórico). Las columnas en verde muestran los datos aritméticos y categóricos de la parroquia a la que pertenece la finca.

La implementación de buenas prácticas ganaderas ayuda a incrementar la capacidad adaptativa y reducir el riesgo climático del sistema ganadero a las diferentes amenazas. 

HERRAMIENTA WEB

El proyecto Ganadería Climáticamente Inteligente ha desarrollado una herramienta web para un fácil procesamiento de los datos en los sistemas ganaderos de Ecuador. Para ello se ha establecido el portal www.ganaderiaclimaticamenteinteligente.com, en cuya sección de “Herramienta de Cálculo de Riesgo Climático” se puede ingresar los datos de la finca.

Para el correcto uso de la herramienta se debe registrar en la página web, en la sección “Iniciar Sesión”, esto permitirá tener un historial de las evaluaciones que se realicen en la finca y poder observar el cambio en las diferentes evaluaciones.

Los resultados de la herramienta generan un archivo PDF con los mismos resultados de la sección 1.5. Sin embargo, en la sección “Mi perfil” del menú desplegable de la derecha, permite revisar el historial de nuestra finca y poder generar comparaciones históricas de las diferentes evaluaciones en el componente de riesgo climático.


BIBLIOGRAFÍA
MAG, MAE, FAO, 2019. Resumen Ejecutivo: Riesgo Climático Actual y Futuro del Sector Ganadero del Ecuador. Quito, Ecuador.

IPCC. 2014. Cambio climático 2014: Informe de síntesis. Contribución de los Grupos de trabajo I, II y III al Quinto Informe de Evaluación del Grupo Intergubernamental de Expertos sobre el Cambio Climático [Equipo principal de redacción, R.K. Pachauri y L.A. Meyer (eds.)]. IPCC. Ginebra, Suiza. 157 págs. 
