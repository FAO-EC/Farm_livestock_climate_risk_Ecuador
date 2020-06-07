## SCRIPT FOR CLIMATE RISK
## FARM LEVEL
## GANADERIA CLIMATICAMENTE INTELIGENTE
## 2019

## ARMANDO RIVERA
## armando.d.rivera@outlook.com

## BASED ON
## Study of climate risk developed on 7 provinces
## www.ganaderiaclimaticamenteinteligente.com

## The script automate the formulas to
## compute climate risk using socioeconomic
## data on the 7 provinces
##
## The results show:
## Adaptive capacity of the pasture 
## Adaptive capacity of the herd
## Climate risk of the pasture
## Climate risk of the herd
## for extreme events in droughts 
## and heavy rains

## Input data must be from one calendar year

########################################
## LIBRARIES
########################################

if (!require("xlsx")) {
  install.packages("xlsx", repos="http://cran.rstudio.com/")
}
library("xlsx")

#######################################
##RESULTS DIRECTORY
########################################

dir_folder = paste("resultados_riesgo_actual", format(Sys.time(), "%Y_%b_%d_%HH_%MM"), sep = "_")
dir.create(dir_folder)

#######################################
##INPUT FILES
########################################

file_name = "input_data.xlsx"
file_data = read.xlsx(file_name, "variables", header=TRUE)
base_datos = "input/actual.csv"
base.credito = "input/datoscredito.csv"

#2. LECTURA Y PREPARACION DE LA BASE DE DATOS
base_data <- read.csv(base_datos, header=TRUE, sep=",")
colnames(base_data)[1] <- "DPA_DESPRO"
base_credito <- read.csv(base.credito, header=TRUE, sep=",")
colnames(base_credito)[1] <- "DPA_DESPRO"
base_credito$DPA_DESPRO = base_credito$DPA_PROVIN


#==========================================
# FUNCIONES
#==========================================

#1.2.Normalizacion cero a uno
#Requiere una tabla de daos, el nombre de la columna a evaluar (nombre en texto)
#se usa la variable ocional "inverse_data" para trabajar variables en la que se resta del maximo valor la variable a analizar
variable.n01_function = function(tabla,columna_a_evaluar,inverse_data=FALSE){
  #se analizan los datos de la columna a evaluar, mediante la resta del maximo valor menos el minimo valor
  max_min = max(tabla[,columna_a_evaluar]) - min(tabla[,columna_a_evaluar])
  #si el valor maximo - minimo es igual a cero, entonces se da por entendido que no hay variacion, adjudicando el resultado 
  #el mismo valor que la columna a evaluar
  if(max_min == 0){
    tabla$nueva_columna = tabla[,columna_a_evaluar]
  }else{
    #cuando si existe variacion de datos en la columna a evaluar
    if(inverse_data == TRUE){ # calcula (maximo - variable)/(maximo - minimo)
      tabla <- transform(tabla, nueva_columna = ifelse(tabla[,columna_a_evaluar] <= 0, 0, # si el valor es cero, se asigna cero al resultado
                                                       (max(tabla[,columna_a_evaluar]) - tabla[,columna_a_evaluar])/
                                                         max_min))
    }else{ # calcula (variable - minimo)/(maximo - minimo)
      tabla <- transform(tabla, nueva_columna = ifelse(tabla[,columna_a_evaluar] <= 0, 0,
                                                       (tabla[,columna_a_evaluar] - min(tabla[,columna_a_evaluar]))/
                                                         max_min))
    }
  }
  resultados_columna = tabla [,"nueva_columna"]
  return(resultados_columna)
}

#1.4. Varianza poblacional
#calcula la varianza poblacional de una lista
varianza = function(lista1){
  varianza_value = var(lista1)*(length(lista1)-1)/length(lista1)
  return(varianza_value)
}


#1.1.Quantiles
#calcula los quantiles de una lista
quantiles_function = function(lista1){
  #lista1=listavariables.capsens
  mean1 = mean(lista1)
  var1 = var(lista1)*(length(lista1)-1)/length(lista1)
  factor1 = (mean1^2)+var1
  a1 = mean1 * (factor1-mean1)/((mean1^2)-factor1)
  b1 = (factor1-mean1)*(1-mean1)/((mean1^2)-factor1)
  q1 = qbeta(0.2, a1, b1)
  q2 = qbeta(0.4, a1, b1)
  q3 = qbeta(0.6, a1, b1)
  q4 = qbeta(0.8, a1, b1)
  return(list(q1=q1,q2=q2,q3=q3,q4=q4))
}

#1.2.Normalizacion cero a uno con datos de finca comparados con los datos de provincia
#esta funcion evalua el valor de una finca con los datos de una lista en la parroquia, asignando el valor correspondiente
finca.n01_function = function(tabla.finca,tabla.provincia,nombre.provincia,finca.columna_a_evaluar){
  
  
  # tabla.finca=finca.tabla
  # tabla.provincia=temp.tabla
  # nombre.provincia=finca_provincia
  # finca.columna_a_evaluar="Infraestructura.multiproposito_riego"
  
  
  
  
  temp.tabla = data.frame()
  for (i in 1:nrow(tabla.provincia)) {
    if (tabla.provincia[i,"DPA_DESPRO"] == nombre.provincia) { #aseguramos que se toman todos los datos de la provincia correspondiente
      temp.tabla <- rbind(temp.tabla,tabla.provincia[i,])
    }
  }
  #Evaluamos el dato de finca:
  #si es cero, se asigna cero al nuevo valor
  #caso contario se aplica la formula: (valor finca - mininimo provincia)/(maximo provincia - minimo provincia)
  maxmin=max(temp.tabla[,finca.columna_a_evaluar]) - min(temp.tabla[,finca.columna_a_evaluar])
  if(maxmin==0){
    maxmin1=tabla.finca[,finca.columna_a_evaluar]
  } else{
    maxmin1=maxmin
  }
  #si el valor es menor al minimo de la provincia, se asigna cero. Si es mayor al maximo de la provincia, se asigna 1
  tabla.finca <- transform(tabla.finca, nueva_columna = ifelse(tabla.finca[,finca.columna_a_evaluar] <=  min(temp.tabla[,finca.columna_a_evaluar]), 0,
                                                               ifelse(tabla.finca[,finca.columna_a_evaluar] >=  max(temp.tabla[,finca.columna_a_evaluar]), 1,
                                                                      (tabla.finca[,finca.columna_a_evaluar] - min(temp.tabla[,finca.columna_a_evaluar]))/
                                                                        (maxmin1))))
  resultados_columna = tabla.finca[,"nueva_columna"]
  return(resultados_columna)
}

#1.4 FUNCION CALCULO DE CAPACIDAD ADAPTATIVA Y SENSIBILIDAD EN PROVINCIA Y FINCA
#La funcion permite calcular la capacidad adaptativa y sensibilidad de la provincia y parroquia
#Si los datos de parroquia y finca no se insertan, solo alcula la capacidad adaptativa o sensibilidad en la provincia
#tabla.provincia = matriz con los datos de las variables provinciales
#nombre.provincia = nombre de la provincia a analizar (texto en "")
#lista.variables.provincia = nombre de las variables que conforman la capacidad adaptativa o sensibilidad (lista). Estas
#deben ser el nombre de las columnas de tabla.provincia
#nombre de la parroquia (opcional) = nombre de la parroquia a analizar (texto en "")
#lista.variables.finca (opcional) = nombre de las variables que conforman la capacidad adaptativa o sensibilidad y que se
#encuentran analizadas a nivel de finca. Estas variables deben estar incluidas dentro de la lista.variables.provincia (lista) y
#deben ser el nombre de las columnas de finca.tabla
#finca.tabla (opcional) = matriz con los datos de variables de la finca
finca.capsens = function(tabla.provincias,nombre.provincia,
                         lista.variables.provincia,nombre.parroquia,
                         lista.variables.finca,finca.tabla){
  
  #tabla.provincias=sensibilidad_aheladas_data
  #nombre.provincia=finca_provincia
  #lista.variables.provincia=provincia.sensibilidad.aheladas.lista
  # nombre.parroquia=finca_parroquia
  # lista.variables.finca=finca.capaciadadaptativa.asequia.lista
  # finca.tabla=finca.base.data
  
  
  #generamos unaq matriz solo con los datos provicniales con el nombre de la provincia a analizar
  temp.tabla = data.frame()
  for (i in 1:nrow(tabla.provincias)) {
    if (tabla.provincias[i,"DPA_DESPRO"] == nombre.provincia) {
      temp.tabla <- rbind(temp.tabla,tabla.provincias[i,])
    }
  }
  w.indice.capsens = 0 #desviacion estandar acumulada de todas las variables 
  sqr.dataframe = data.frame() # lista de desviaciones estandar por cada variable
  
  for(i in lista.variables.provincia){
    #se normaliza de cero a uno utilizando la funcion variable.n01_function de todas las variables que intervienen
    #se acumula en temp.table los resultados de cada variable con nombre de la variable terminado en "n.01"
    temp.tabla[,paste(i,".n01",sep = "")] <- variable.n01_function(temp.tabla,i)
    var.i = varianza(temp.tabla[,paste(i,".n01",sep="")])
    sqr.i = var.i^(1/2)
    sqr.dataframe = c(sqr.dataframe, sqr.i)
    w.indice.capsens = w.indice.capsens+sqr.i
  }
  #fraccion que representa cada desviacion estandar en relacion a la desviacion estandar acumulada
  w.dataframe = data.frame()
  for (i in sqr.dataframe) {
    w.i = ifelse(w.indice.capsens==0,0, i/w.indice.capsens)
    w.dataframe = c(w.dataframe,w.i)
  }
  #generamos una columna para realizar el calculo de capacidad adaptativa o sensibilidad
  temp.tabla = transform(temp.tabla,nueva_columna = 0)
  listavariables.capsens = double() #lista que acumulara todas los datos de todas las variables que conforman el calculo
  for (i in 1:length(lista.variables.provincia)) {
    #Se calcula multiplicando cada valor de la variable normalizada con su peso respectivo
    temp.tabla = transform(temp.tabla,nueva_columna = nueva_columna +
                             temp.tabla[,paste(lista.variables.provincia[[i]],".n01",sep = "")]*w.dataframe[[i]])
    #se acumula cada dato en una lista
    listavariables.capsens = c(listavariables.capsens, temp.tabla[,paste(lista.variables.provincia[[i]],".n01",sep = "")])
  }
  #cambiamos el nombre de la columna por "capsens" 
  colnames(temp.tabla)[ colnames(temp.tabla) == "nueva_columna" ] <- "capsens"
  #generamos los quantiles en la lista de datos de las variables
  quantiles.indice.capsens = quantiles_function(listavariables.capsens)
  
  #si los datos de parroquia no se insertan,retorna los datos de provincia
  if(missing(nombre.parroquia)|missing(lista.variables.finca)|missing(finca.tabla)) {
    return(list(tabla.capsens = temp.tabla[,c("DPA_DESPRO","DPA_DESPAR","capsens")], quantiles.resultados = quantiles.indice.capsens, datos.variables = listavariables.capsens ))
    #calculo de parroquia y provincia 
  }else {
    #extrae el dato de capsens de la parroquia desde temp.table
    parroquia.capsens = temp.tabla[temp.tabla$DPA_DESPAR == nombre.parroquia,]$capsens
    #se extrae el numero de fila de los datos de la parroquia desde matriz de datos de temp.tabla
    finca.row.number = which(temp.tabla$DPA_DESPAR==nombre.parroquia & temp.tabla$DPA_DESPRO==nombre.provincia)
    #se genera una matriz con los datos de la parroquia desde temp.table, esta incluye todas las variables por defecto
    #de la parroquia a la cual pertenece la finca
    finca.base = temp.tabla[finca.row.number,]
    for (i in lista.variables.finca) {
      
      #se normaliza el dato de parroquia con la funcion finca.n01_function, en relacion al dato provincial
      finca.base[,paste(i,".n01",sep = "")] <- finca.n01_function(finca.tabla,temp.tabla,finca_provincia,i)
      #se adiciona los datos de cada variable a los datos de finca
      finca.base[,i] = finca.tabla[,i]
    }
    #se genera una columna para el calculo de sensibilidad o capacidad adaptativa a nivel de finca
    finca.tabla = transform(finca.tabla,nueva_columna = 0)
    #se calcula utilizando los datos de finca.base que incluye cada variable de la finca, multiplicando por el peso
    #provincial calculado previamente
    for (i in 1:length(lista.variables.provincia)) {
      finca.tabla = transform(finca.tabla,nueva_columna = nueva_columna +
                                finca.base[,paste(lista.variables.provincia[[i]],".n01",sep = "")]*w.dataframe[[i]])
    }
    #cambio de nombre de la nueva columna
    colnames(finca.tabla)[ colnames(finca.tabla) == "nueva_columna" ] <- "capsens"
    return(list(finca.tabla.capsens = finca.tabla$capsens, parroquia.tabla.capsens = parroquia.capsens,
                quantiles.resultados = quantiles.indice.capsens, datos.variables = listavariables.capsens))
  }
}

#1.5 NORMALIZACION 1 - 5
#La función, categoriza los valores de una lista, comparandolos con sus quantiles
calificar_quantiles_function = function(value1,lista_quantiles){
  if(is.nan(lista_quantiles$q1) == FALSE & value1<=lista_quantiles$q1){
    calificacion = 1
  }else if(is.nan(lista_quantiles$q1) == FALSE & is.nan(lista_quantiles$q2) == FALSE & value1>lista_quantiles$q1 & value1<=lista_quantiles$q2){
    calificacion = 2
  }else if(is.nan(lista_quantiles$q2) == FALSE & is.nan(lista_quantiles$q3) == FALSE & value1>lista_quantiles$q2 & value1<=lista_quantiles$q3){
    calificacion = 3
  }else if(is.nan(lista_quantiles$q3) == FALSE & is.nan(lista_quantiles$q4) == FALSE & value1>lista_quantiles$q3 & value1<=lista_quantiles$q4){
    calificacion = 4
  }else if(is.nan(lista_quantiles$q4) == FALSE & value1>lista_quantiles$q4){
    calificacion = 5
  }else(
    calificacion = NA
  )
  return(calificacion)
}


## -------------------------------------
## CLIMATE RSIK ESTIMATION
## -------------------------------------
## Compute climate risk from cattle production
##
## The results show a value between 0 and 1
## and show the category
## 1. VERY LOW
## 2. LOW
## 3. MODERATE
## 4. HIGH
## 5. VERI HIGH

for(i in 1:nrow(file_data)){
  if(file_data[i,"finca"] != ""){
    
    #nombre productor
    nombre_finca = toString(file_data[i,"finca"])
    fecha_finca = toString(file_data[i,"fecha"])
    nombre_productor = paste(nombre_finca,"_",fecha_finca, sep = "")
      
    ##ubicacion
    finca_parroquia = as.numeric(file_data[i,"parroquia_id"])
    finca_provincia = as.numeric(substr(finca_parroquia, 1, nchar(finca_parroquia)-4))
    
    ##datos hato 
    finca_vacas = file_data[i,"vacas"]
    finca_vaconas = file_data[i,"vaconas"]
    finca_terneras = file_data[i,"terneras"]
    finca_toros = file_data[i,"toros"]
    finca_toretes = file_data[i,"toretes"]
    finca_terneros = file_data[i,"terneros"]
    
    ##datos finca
    superficie_finca_ha = file_data[i,"superficie_finca_ha"]
    superficie_conservacion_ha = file_data[i,"superficie_conservacion_ha"]
    superficie_plantaciones_forestales_ha = file_data[i,"superficie_plantaciones_forestales_ha"]
    
    ##pastos
    superficie_pastos_ha = file_data[i,"superficie_pastos_ha"]
    superficie_silvopastoril_ha = file_data[i,"superficie_pastos_con_silvopastoril_ha"]
    
    ##pasto manejado
    pasto_manejo_siembra_sino = toString(file_data[i,"siembra_resiembra_pastos_sino"])
    pasto_manejo_fertilizacion_sino = toString(file_data[i,"fertiliza_pastos_sino"])
    pasto_manejo_division_potreros_sino = toString(file_data[i,"division_potreros_pastoreo_rotacional_sino"])
    superficie_pastos_manejo_ha = file_data[i,"superficie_pastos_manejados_ha"]
    
    ##ataques de ganado
    ataques_ganado_animales_silvestres_sino= toString(file_data[i,"ataques_animales_silvestres_sino"])
    
    ##Acceso a fuentes de agua natural
    vertientes_sino = toString(file_data[i,"vertientes_naturales_sino"])
    ojos_agua_sino = toString(file_data[i,"ojos_agua_sino"])
    quebradas_sino = toString(file_data[i,"acceso_quebradas_sino"])
    rios_sino = toString(file_data[i,"acceso_rios_sino"])
    agua_subterranea_sino = toString(file_data[i,"agua_subterranea_sino"])
    
    ##Sistemas de captación de agua:
    escases_agua_sino = toString(file_data[i,"escases_agua_sino"])
    agua_entubada_sino = toString(file_data[i,"agua_entubada_riego_sino"])
    albarrada_reservorio_sino = toString(file_data[i,"albarradas_reservorios_sino"])
    sistema_riego_sino = toString(file_data[i,"sistema_riego_sino"])
    superficie_riego_pastos_cultivos_ganado_ha = file_data[i,"superficie_riego_ha"] ######## PASTOS NATURALES CON ARBOLES, NATIURALES SIN ARBOLES, MEJORADOS CON ARBOLES, MEJORADOS SIN ARBOLES, ALIMENTACION GANADO
    
    inundaciones_sino = toString(file_data[i,"inundaciones_sino"])
    drenajes_sino = toString(file_data[i,"drenajes_sino"])
    

    ##cercas vivas
    porcentaje_linderos_cercas_vivas = file_data[i,"porcentaje_linderos_cercas_vivas_."]
    
    #cultivos asociados alimentación del ganado:** 
    cultivo_asociados_ganado_siembra_sino = toString(file_data[i,"cultivos_asociados_sino"])
    superficie_cultivos_asociados_ganado_ha = file_data[i,"cultivos_asociados_ha"]
    cultivo_asociados_ganado="ninguno" #1. maiz forrajero 2. pasto de corte 3. caña 4. Otro: 
    cultivo_asociados_falta_alimento = toString(file_data[i,"escases_alimento"]) #1. NO  2. si  3. si_conservacion
    
    #Herramientas de planificación:
    plan_finca = toString(file_data[i,"planificacion_forrajera"]) # a. ninguno a. elaborado b. ejecucion
    calendario_reproduccion = toString(file_data[i,"calendario_reproductivo"]) # a. ninguno a. elaborado b. ejecucion
    calendario_sanitario = toString(file_data[i,"plan_vacunacion_desparasitacion"]) # a. ninguno a. elaborado b. ejecucion
    
    ##infraestructura_ganadera 
    infraestructura_corral = toString(file_data[i,"corral_sino"])
    infraestructura_manga = toString(file_data[i,"manga_sino"])
    infraestructura_caseta = toString(file_data[i,"caseta_ordeno_sino"])
    infraestructura_comedero = toString(file_data[i,"comedero_sino"])
    infraestructura_pesebreras = toString(file_data[i,"pesebrera_cuna_sino"])
    infraestructura_bodegas = toString(file_data[i,"bodega_sino"])
    infraestructura_alzaderos = toString(file_data[i,"alzadero_sino"])
    infraestructura_bebederos = toString(file_data[i,"bebederos_sino"])
    
    if(infraestructura_corral == "SI"){
      infraestructura_corral_value = 1
    }else(
      infraestructura_corral_value = 0
    )
    if(infraestructura_manga == "SI"){
      infraestructura_manga_value = 1
    }else(
      infraestructura_manga_value = 0
    )
    if(infraestructura_caseta == "SI"){
      infraestructura_caseta_value = 1
    }else(
      infraestructura_caseta_value = 0
    )
    if(infraestructura_comedero == "SI"){
      infraestructura_comedero_value = 1
    }else(
      infraestructura_comedero_value = 0
    )
    if(infraestructura_pesebreras == "SI"){
      infraestructura_pesebreras_value = 1
    }else(
      infraestructura_pesebreras_value = 0
    )
    if(infraestructura_bodegas == "SI"){
      infraestructura_bodegas_value = 1
    }else(
      infraestructura_bodegas_value = 0
    )
    if(infraestructura_alzaderos == "SI"){
      infraestructura_alzaderos_value = 1
    }else(
      infraestructura_alzaderos_value = 0
    )
    if(infraestructura_bebederos == "SI"){
      infraestructura_bebederos_value = 1
    }else(
      infraestructura_bebederos_value = 0
    )
    infraestructura_value = (infraestructura_corral_value+infraestructura_manga_value+
      infraestructura_caseta_value+infraestructura_comedero_value+
      infraestructura_pesebreras_value+infraestructura_bodegas_value+
      infraestructura_alzaderos_value+infraestructura_bebederos_value)/8
    
    #mecanismo financiero:
    credito_acceso = toString(file_data[i,"credito_acceso_sino"])
    credito_financiero = file_data[i,"credito_usd"]
    recursos_adicionales = file_data[i,"monto_inversion_fuera_del_credito_usd"]
    
    #sistema productivo
    sistema_productivo = toString(file_data[i,"sistema_productivo"]) #a. marginal b. mercantil c. combinado d. empresarial
    
    #Acceso a información del clima
    acceso_clima = toString(file_data[i,"uso_informacion_clima"]) #a. NO  b.internet  c. telefonos inteligentes  d. noticias 
    
    #############################################################
    ## CALCULOS DE HOMOLOGACION
    #############################################################
    
    ##Porcentaje de riego
    porc_riego.coeficiente = ifelse((superficie_pastos_ha + superficie_cultivos_asociados_ganado_ha) == 0,0,
                                    superficie_riego_pastos_cultivos_ganado_ha / 
                                      (superficie_pastos_ha +  superficie_cultivos_asociados_ganado_ha)*100)
    
    ##Sistemas de captación de agua: # Infraestructura.multiproposito_riego
    if(escases_agua_sino == "SI"){
      if(agua_entubada_sino == "SI"){ 
        agua_entubada_value = 0.3333
      } else (
        agua_entubada_value = 0
      )
      if(albarrada_reservorio_sino == "SI"){ 
        albarrada_reservorio_value = 0.3333
      } else (
        albarrada_reservorio_value = 0
      )
      if(sistema_riego_sino == "SI"){
        sistema_riego_value = 0.3333
      } else (
        sistema_riego_value = 0
      )
      Infraestructura.multiproposito_riego_coeficiente_sequia = agua_entubada_value+
        albarrada_reservorio_value + 
        sistema_riego_value
    } else (
      Infraestructura.multiproposito_riego_coeficiente_sequia = 1
    )
    
    if(inundaciones_sino == "SI"){
      if(drenajes_sino == "SI"){ 
        Infraestructura.multiproposito_riego_coeficiente_lluvias = 1
      } else (
        Infraestructura.multiproposito_riego_coeficiente_lluvias = 0
      )
    } else (
      Infraestructura.multiproposito_riego_coeficiente_lluvias = 1
    )
    
    ##Indice de red hidrica
    if(vertientes_sino == "SI" | 
       ojos_agua_sino == "SI" | 
       quebradas_sino == "SI" | 
       rios_sino == "SI" | 
       agua_subterranea_sino == "SI" 
    ){
      indice_red_hidrica_coeficiente = 1
    } else (
      indice_red_hidrica_coeficiente = 0
    )
    
    ##pasto manejo
    if(pasto_manejo_siembra_sino == "SI"){
      pasto_manejo_siembra_value = 0.3333
    } else (
      pasto_manejo_siembra_value = 0
    )
    if(pasto_manejo_fertilizacion_sino == "SI"){
      pasto_manejo_fertilizacion_value = 0.3333
    } else (
      pasto_manejo_fertilizacion_value = 0
    )
    if(pasto_manejo_division_potreros_sino == "SI"){
      pasto_manejo_division_potreros_value = 0.3333
    } else (
      pasto_manejo_division_potreros_value = 0
    )
    pasto_manejo_coeficiente = pasto_manejo_siembra_value + pasto_manejo_fertilizacion_value + pasto_manejo_division_potreros_value
    
    #cultivo asociados alimentación del ganado:
    #cultivo_asociados_falta_alimento = "NO" #1. NO  2. SI  3. SI, Y HACE CONSERVACION DE FORRAJES
    if(cultivo_asociados_ganado_siembra_sino == "SI"){
      cultivo_asociados_ganado_siembra_value = 0.5
    } else (
      cultivo_asociados_ganado_siembra_value = 0
    )
    if(cultivo_asociados_falta_alimento == "NO" | 
       cultivo_asociados_falta_alimento == "SI, Y HACE CONSERVACION DE FORRAJES"){
      cultivo_asociados_falta_alimento_value = 0.5
    } else (
      cultivo_asociados_falta_alimento_value = 0
    )
    cultivo_asociados_ganado_coeficiente = cultivo_asociados_ganado_siembra_value + cultivo_asociados_falta_alimento_value
    
    #Herramientas de planificación:
    if(plan_finca == "ELABORADO"){
      plan_finca_value = 0.12
    } else if (plan_finca == "EN EJECUCION"){
      plan_finca_value = 0.24
    } else (
      plan_finca_value = 0
    )
    if(calendario_reproduccion == "ELABORADO"){
      calendario_reproduccion_value = 0.12
    } else if (calendario_reproduccion == "EN EJECUCION"){
      calendario_reproduccion_value = 0.24
    } else (
      calendario_reproduccion_value = 0
    )
    if(calendario_sanitario == "ELABORADO"){
      calendario_sanitario_value = 0.12
    } else if (calendario_sanitario == "EN EJECUCION"){
      calendario_sanitario_value = 0.24
    } else (
      calendario_sanitario_value = 0
    )
    infraestructura_ganadera_value = ifelse(infraestructura_value==0,0,0.28*infraestructura_value)
    herramienta_planificacion_coeficiente = plan_finca_value + calendario_reproduccion_value + calendario_sanitario_value + infraestructura_ganadera_value
    
    #sistemas productivos
    if(sistema_productivo == "MARGINAL"){
      sistema.productivo.coeficiente = 1
      } else if(sistema_productivo == "MERCANTIL"){
      sistema.productivo.coeficiente = 2
      } else if(sistema_productivo == "COMBINADO"){
      sistema.productivo.coeficiente = 3
      } else if(sistema_productivo == "EMPRESARIAL"){
      sistema.productivo.coeficiente = 4
      }
    
    
    #Disponibilidad del pronostico del clima
    if(acceso_clima == "NO"){
      disponibilidad_pronostico_clima.coeficiente = 0
    } else (
      disponibilidad_pronostico_clima.coeficiente = 1
    )
    
    #Conflicto gente fauna
    if(ataques_ganado_animales_silvestres_sino == "SI"){
      conflicto.gente.fauna.coeficiente = 1
    } else (
      conflicto.gente.fauna.coeficiente = 0
    )
    
    #pastos
    
    superficie_cercas_vivas =((((2.528*(superficie_finca_ha))+
                                  1.9848)*0.02)*(porcentaje_linderos_cercas_vivas/100))
    
    cobertura_vegetacion_natural_ambiental = ifelse(superficie_finca_ha == 0,0,
                                                    (superficie_conservacion_ha + 
                                                superficie_plantaciones_forestales_ha +
                                                superficie_silvopastoril_ha + 
                                                superficie_cercas_vivas) / superficie_finca_ha * 100)
    
    cobertura_vegetacion_natural_socioeconomico = ifelse(superficie_finca_ha == 0,0,
                                                         (superficie_conservacion_ha + 
                                                            superficie_plantaciones_forestales_ha +
                                                            superficie_silvopastoril_ha +  
                                                            superficie_cercas_vivas +
                                                            (superficie_pastos_manejo_ha * pasto_manejo_coeficiente) +
                                                            (superficie_cultivos_asociados_ganado_ha * cultivo_asociados_ganado_coeficiente)
                                                          ) / superficie_finca_ha * 100)
    
    presencia_sociobosque.coeficiente = ifelse(superficie_finca_ha == 0,0,
                                               superficie_conservacion_ha / superficie_finca_ha * 100)
    
    estimado_volumen_credito.coeficiente = credito_financiero + recursos_adicionales
    
    #==========================================
    # CALCULOS
    #==========================================
    
    # Tabla con los datos ingresados de la finca
    base_data$DPA_DESPRO = trunc(base_data$DPA_PARROQ/10000)
    base_data$DPA_DESPAR = base_data$DPA_PARROQ
    
    finca.row = which(base_data$DPA_DESPAR==finca_parroquia) # extrae los datos base de la base nacional
    finca.base.data = base_data[finca.row,1:4]
    
    finca.base.data$area = superficie_finca_ha #ingreso en la tabla de datos ingresados de finca
    finca.base.data$pastos_area = superficie_pastos_ha
    finca.base.data$cultivos_asociados_area = superficie_cultivos_asociados_ganado_ha
    finca.base.data$Porc_riego = porc_riego.coeficiente
    #finca.base.data$Infraestructura.multiproposito_riego_sequia = Infraestructura.multiproposito_riego_coeficiente_sequia
    #finca.base.data$Infraestructura.multiproposito_riego_lluvias = Infraestructura.multiproposito_riego_coeficiente_lluvias
    
   
    
    province.finca.base.data = base_data[base_data$DPA_DESPRO==finca_provincia,
                                         c("DPA_DESPRO",
                                           "DPA_DESPAR",
                                           "Indice.de.red.hidrica")]
    finca.base.data$Indice.de.red.hidrica = indice_red_hidrica_coeficiente * province.finca.base.data[province.finca.base.data$DPA_DESPAR==finca_parroquia,"Indice.de.red.hidrica"]
    finca.base.data$Presencia.de.sociobosque.... = presencia_sociobosque.coeficiente
    finca.base.data$Herramientas.de.planificacion.CC = herramienta_planificacion_coeficiente
    finca.base.data$Estimado.de.volumen.de.credito <- estimado_volumen_credito.coeficiente
    finca.base.data$Sistemas.productivos.pecuarios <- sistema.productivo.coeficiente
    finca.base.data$Disponibilidad.de.pronostico.del.clima = disponibilidad_pronostico_clima.coeficiente
    finca.base.data$Conflicto.gente.fauna = conflicto.gente.fauna.coeficiente
    
    finca.base.data$vacas = finca_vacas
    finca.base.data$vaconas = finca_vaconas
    finca.base.data$terneras = finca_terneras
    finca.base.data$toros = finca_toros
    finca.base.data$toretes = finca_toretes
    finca.base.data$terneros = finca_terneros
    
    
    #==========================================
    #AMBIENTAL
    #==========================================
    
    #3. AMBIENTAL SEQUIA
    #==========================================
    
    #3.1 AMENAZA TENDENCIA SEQUIA
    amenaza.asequia.lista.provincia = c("ACTUAL.CDD",
                                        "ACTUAL.SPI")
    columnas_amenaza_asequia_data = c("DPA_DESPRO",
                                      "DPA_DESPAR",
                                      amenaza.asequia.lista.provincia) # columnas de la base provincial que intervienen en amenaza sequia
    amenaza_asequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_amenaza_asequia_data] #construccion de la base adicional
    amenaza_asequia_data$ACTUAL.CDD.N01<- variable.n01_function(amenaza_asequia_data,"ACTUAL.CDD")
    #SPI cambia su orden en relacion a la funcion variable.n01_function. Siendo (max - dato)/(max - min)
    amenaza_asequia_data$ACTUAL.SPI.N01<- ifelse(amenaza_asequia_data$ACTUAL.SPI >= 0, 0,
                                                 ((max(amenaza_asequia_data$ACTUAL.SPI) - (amenaza_asequia_data$ACTUAL.SPI))/
                                                    (max(amenaza_asequia_data$ACTUAL.SPI) - min(amenaza_asequia_data$ACTUAL.SPI)))) 
    # amenaza se genera de la suma de CDD y SPI
    amenaza_asequia_data$Amenaza.Tendencia.asequia.n01 <- ((amenaza_asequia_data$ACTUAL.CDD.N01 + amenaza_asequia_data$ACTUAL.SPI.N01)/2)
    amenaza_asequia_finca = amenaza_asequia_data[amenaza_asequia_data$DPA_DESPAR==finca_parroquia,"Amenaza.Tendencia.asequia.n01"]
    
    #3.2 EXPOSICION TENDENCIA SEQUIA
    exposicion.asequia.lista.provincia = c("Exposicion.pasto....")
    columnas_exposicion_asequia_data = c("DPA_DESPRO",
                                         "DPA_DESPAR",
                                         exposicion.asequia.lista.provincia) #columnas de exposicion
    exposicion_asequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_exposicion_asequia_data] #construccion de la tabla con las columnas q intervienen
    
    finca.base.data$Exposicion.pasto.... =  ifelse(finca.base.data$area == 0,0,
                                                   (finca.base.data$pastos_area/finca.base.data$area*100)) # calculo de exposicion en finca
    #calculo de exposicion en finca
    finca.base.data$Exposicion.pasto.....n01 <- finca.n01_function(finca.base.data,exposicion_asequia_data,finca_provincia,"Exposicion.pasto....")
    
    #3.3 SENSIBILIDAD SEQUIA
    #calculo de carga animal en la base provincial
    base_data$Carga.Animal <- ifelse(base_data$PASTOS > 0, base_data$UBAS/
                                       (base_data$PASTOS+base_data$CULT..ASOC),0)
    
    finca.sensibilidad.asequia.lista= c("Carga.Animal")
    provincia.sensibilidad.asequia.lista = c("capacidad.de.uso.de.la.tierra_parr..SEN1.",
                                             "Degradacion_parr","Defor_2014_2016",
                                             "Carga.Animal")
    
    columnas_sensibilidad_asequia_data = c("DPA_DESPRO","DPA_DESPAR",
                                           provincia.sensibilidad.asequia.lista) 
    sensibilidad_asequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_sensibilidad_asequia_data] #construccion de la tabla con las columnas q intervienen
    
    #calculo de UBAS en finca
    finca.base.data$UBAS = finca.base.data$vacas+(finca.base.data$vaconas*0.7)+(finca.base.data$terneras*0.6)+
      (finca.base.data$toros*1.3)+(finca.base.data$toretes*0.7)+(finca.base.data$terneros*0.6)
    
    #calculo de carga animal finca
    finca.base.data$Carga.Animal = ifelse((finca.base.data$pastos_area + finca.base.data$cultivos_asociados_area) == 0,0,
                                          finca.base.data$UBAS/(finca.base.data$pastos_area+ 
                                                            finca.base.data$cultivos_asociados_area))
    
    sensibilidad.asequia.finca = finca.capsens(sensibilidad_asequia_data,finca_provincia, 
                                               provincia.sensibilidad.asequia.lista,finca_parroquia,finca.sensibilidad.asequia.lista,
                                               finca.base.data)
    sensibilidad.asequia.provincia = finca.capsens(sensibilidad_asequia_data,finca_provincia, 
                                                   provincia.sensibilidad.asequia.lista)
    
    #3.4 CAPACIDAD ADAPTATIVA SEQUIA
    
    finca.base.data$Infraestructura.multiproposito_riego = Infraestructura.multiproposito_riego_coeficiente_sequia
    #finca.base.data$Infraestructura.multiproposito_riego = Infraestructura.multiproposito_riego_coeficiente_lluvias
    finca.capaciadadaptativa.asequia.lista= c("Infraestructura.multiproposito_riego",
                                              "Porc_riego",
                                              "Porc_Cobert_Nat",
                                              "Indice.de.red.hidrica",
                                              "Presencia.de.sociobosque....")
    
    provincia.capaciadadaptativa.asequia.lista = c("Infraestructura.multiproposito_riego",
                                                   "Porc_riego",
                                                   "Porc_Cobert_Nat",
                                                   "Indice.de.red.hidrica",
                                                   "Presencia.de.sociobosque....")
    
    columnas_capaciadadaptativa_asequia_data = c("DPA_DESPRO","DPA_DESPAR",provincia.capaciadadaptativa.asequia.lista)
    capaciadadaptativa_asequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_capaciadadaptativa_asequia_data] #construccion de la tabla con las columnas q intervienen
    
    #calculo de variables a nivel de finca
    finca.base.data$Porc_Cobert_Nat = cobertura_vegetacion_natural_ambiental
    
    
    capaciadadaptativa.asequia.finca = finca.capsens(capaciadadaptativa_asequia_data,
                                                     finca_provincia, 
                                                     provincia.capaciadadaptativa.asequia.lista,
                                                     finca_parroquia,
                                                     finca.capaciadadaptativa.asequia.lista,
                                                     finca.base.data)
    
    capaciadadaptativa.asequia.provincia = finca.capsens(capaciadadaptativa_asequia_data,finca_provincia, 
                                                         provincia.capaciadadaptativa.asequia.lista)
    
    #3.5 INDICE VULNERABILIDAD SEQUIA
    columnas_vulnerabilidad_asequia_data = c("DPA_DESPRO","DPA_DESPAR")
    vulnerabilidad_asequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_vulnerabilidad_asequia_data] #construccion de la tabla con las columnas q intervienen
    vulnerabilidad_asequia_data$sensibilidad = sensibilidad.asequia.provincia$tabla.capsens$capsens
    vulnerabilidad_asequia_data$capacidad.adaptativa = capaciadadaptativa.asequia.provincia$tabla.capsens$capsens
    
    # Calculo de la capacidad adaptativa en la provincia
    vulnerabilidad_asequia_data$vulnerabilidad = ifelse(vulnerabilidad_asequia_data$capacidad.adaptativa==0,vulnerabilidad_asequia_data$sensibilidad/0.0012, vulnerabilidad_asequia_data$sensibilidad/vulnerabilidad_asequia_data$capacidad.adaptativa)
    # Calculo de la capacidad adaptativa en finca
    vulnerabilidad_asequia_finca = finca.base.data
    # cuando la capacidad apadptativa es cero, se le asigna el valor de 0.0012, que es el valor mas bajo del estudio
    vulnerabilidad_asequia_finca$vulnerabilidad = ifelse(capaciadadaptativa.asequia.finca$finca.tabla.capsens==0,sensibilidad.asequia.finca$finca.tabla.capsens/ 0.0012, 
                                                         sensibilidad.asequia.finca$finca.tabla.capsens/capaciadadaptativa.asequia.finca$finca.tabla.capsens)
    #comparacion finca provincia
    vulnerabilidad_asequia_finca$vulnerabilidad.n01 = finca.n01_function(vulnerabilidad_asequia_finca,vulnerabilidad_asequia_data,
                                                                         finca_provincia,"vulnerabilidad")
    
    #3.6 INDICE RIESGO CLIMATICO SEQUIA
    columnas_riesgoclimatico_asequia_data = c("DPA_DESPRO","DPA_DESPAR")
    riesgoclimatico_asequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_riesgoclimatico_asequia_data] #construccion de la tabla con las columnas q intervienen
    riesgoclimatico_asequia_data$amenaza = amenaza_asequia_data$Amenaza.Tendencia.asequia.n01
    riesgoclimatico_asequia_data$exposicion = variable.n01_function(exposicion_asequia_data,"Exposicion.pasto....")
    riesgoclimatico_asequia_data$vulnerabilidad = variable.n01_function(vulnerabilidad_asequia_data,"vulnerabilidad")
    
    # Calculo de la capacidad adaptativa en la provincia
    riesgoclimatico_asequia_data$riesgoclimatico = (riesgoclimatico_asequia_data$amenaza*
                                                      riesgoclimatico_asequia_data$exposicion*
                                                      riesgoclimatico_asequia_data$vulnerabilidad)^(1/3)
    
    riesgoclimatico_asequia_data$riesgoclimatico.n01 = variable.n01_function(riesgoclimatico_asequia_data,
                                                                             "riesgoclimatico")
    
    # Calculo de la capacidad adaptativa en finca
    riesgoclimatico_asequia_finca = finca.base.data
    riesgoclimatico_asequia_finca$riesgoclimatico = ifelse((amenaza_asequia_finca*
                                                              riesgoclimatico_asequia_finca$Exposicion.pasto.....n01*
                                                              vulnerabilidad_asequia_finca$vulnerabilidad.n01)< 0,0,
                                                           (amenaza_asequia_finca*
                                                              riesgoclimatico_asequia_finca$Exposicion.pasto.....n01*
                                                              vulnerabilidad_asequia_finca$vulnerabilidad.n01)^(1/3))
    
    riesgoclimatico_asequia_finca$riesgoclimatico.n01 = finca.n01_function(riesgoclimatico_asequia_finca,
                                                                           riesgoclimatico_asequia_data,
                                                                           finca_provincia,"riesgoclimatico")
    
    #3.7 RESULTADOS
    asequia.amenaza.finca = amenaza_asequia_finca
    asequia.amenaza.parroquia = riesgoclimatico_asequia_data[riesgoclimatico_asequia_data$DPA_DESPAR==finca_parroquia,"amenaza"]
    
    asequia.exposicion.finca = riesgoclimatico_asequia_finca$Exposicion.pasto.....n01
    asequia.exposicion.parroquia = riesgoclimatico_asequia_data[riesgoclimatico_asequia_data$DPA_DESPAR==finca_parroquia,"exposicion"]
    
    asequia.sensibilidad.finca = sensibilidad.asequia.finca$finca.tabla.capsens
    asequia.sensibilidad.parroquia = sensibilidad.asequia.finca$parroquia.tabla.capsens
    
    asequia.capacidadadaptativa.finca = capaciadadaptativa.asequia.finca$finca.tabla.capsens
    asequia.capacidadadaptativa.parroquia = capaciadadaptativa.asequia.finca$parroquia.tabla.capsens
    
    asequia.vulnerabilidad.finca = vulnerabilidad_asequia_finca$vulnerabilidad.n01
    asequia.vulnerabilidad.parroquia = riesgoclimatico_asequia_data[riesgoclimatico_asequia_data$DPA_DESPAR==finca_parroquia,"vulnerabilidad"]
    
    asequia.riesgoclimatico.finca = riesgoclimatico_asequia_finca$riesgoclimatico.n01
    asequia.riesgoclimatico.parroquia = riesgoclimatico_asequia_data[riesgoclimatico_asequia_data$DPA_DESPAR==finca_parroquia,"riesgoclimatico.n01"]
    
    
    #4. AMBIENTAL HELADAS
    #==========================================

    #4.1 AMENAZA TENDENCIA HELADAS
    amenaza.aheladas.lista.provincia = c("ACTUAL.Amenaz.Tendencia.Heladas_parr")
    columnas_amenaza_aheladas_data = c("DPA_DESPRO","DPA_DESPAR",amenaza.aheladas.lista.provincia) # columnas de la base provincial que intervienen en amenaza HELADAS
    amenaza_aheladas_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_amenaza_aheladas_data] #construccion de la base adicional
    amenaza_aheladas_data$Heladas_parr.N01<- variable.n01_function(amenaza_aheladas_data,"ACTUAL.Amenaz.Tendencia.Heladas_parr")
    amenaza_aheladas_finca = amenaza_aheladas_data[amenaza_aheladas_data$DPA_DESPAR==finca_parroquia,"Heladas_parr.N01"]

    #4.2 EXPOSICION TENDENCIA HELADAS
    #Ver 3.2 exposicion pastos
    exposicion_aheladas_data = exposicion_asequia_data

    #4.3 SENSIBILIDAD HELADAS
    sensibilidad.aheladas.lista.provincia = ("Indi_.heladas_CIIFEN")
    columnas_sensibilidad_aheladas_data = c("DPA_DESPRO","DPA_DESPAR",sensibilidad.aheladas.lista.provincia) #columnas de sensibilidad
    sensibilidad_aheladas_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_sensibilidad_aheladas_data] #construccion de la tabla con las columnas q intervienen

    provincia.sensibilidad.aheladas.lista = c("Indi_.heladas_CIIFEN")
    sensibilidad.aheladas.provincia = finca.capsens(sensibilidad_aheladas_data,finca_provincia,
                                                    provincia.sensibilidad.aheladas.lista)
    sensibilidad.aheladas.finca = sensibilidad.aheladas.provincia$tabla.capsens[sensibilidad.aheladas.provincia$tabla.capsens$DPA_DESPAR==finca_parroquia,"capsens"]

    #4.4 CAPACIDAD ADAPTATIVA HELADAS
    capacidadadaptativa.aheladas.lista.provincia = c("Porc_Cobert_Nat","Pend_parr","Presencia.de.sociobosque....")
    columnas_capaciadadaptativa_aheladas_data = c("DPA_DESPRO","DPA_DESPAR",capacidadadaptativa.aheladas.lista.provincia)
    capaciadadaptativa_aheladas_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_capaciadadaptativa_aheladas_data] #construccion de la tabla con las columnas q intervienen

    #calculo de variables a nivel de finca
    #Porc_Cobert_Nat finca ver 4.2
    finca.capaciadadaptativa.aheladas.lista= c("Porc_Cobert_Nat","Presencia.de.sociobosque....")
    provincia.capaciadadaptativa.aheladas.lista = c("Porc_Cobert_Nat","Pend_parr","Presencia.de.sociobosque....")
    capaciadadaptativa.aheladas.finca = finca.capsens(capaciadadaptativa_aheladas_data,finca_provincia,
                                                      provincia.capaciadadaptativa.aheladas.lista,finca_parroquia,finca.capaciadadaptativa.aheladas.lista,
                                                      finca.base.data)
    capaciadadaptativa.aheladas.provincia = finca.capsens(capaciadadaptativa_aheladas_data,finca_provincia,
                                                          provincia.capaciadadaptativa.aheladas.lista)

    #4.5 INDICE VULNERABILIDAD HELADAS
    columnas_vulnerabilidad_aheladas_data = c("DPA_DESPRO","DPA_DESPAR")
    vulnerabilidad_aheladas_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_vulnerabilidad_aheladas_data] #construccion de la tabla con las columnas q intervienen
    vulnerabilidad_aheladas_data$sensibilidad = sensibilidad.aheladas.provincia$tabla.capsens$capsens
    vulnerabilidad_aheladas_data$capacidad.adaptativa = capaciadadaptativa.aheladas.provincia$tabla.capsens$capsens

    # Calculo de la capacidad adaptativa en la provincia
    vulnerabilidad_aheladas_data$vulnerabilidad = ifelse(vulnerabilidad_aheladas_data$capacidad.adaptativa == 0,vulnerabilidad_aheladas_data$sensibilidad/0.0012, vulnerabilidad_aheladas_data$sensibilidad/vulnerabilidad_aheladas_data$capacidad.adaptativa)
    # Calculo de la capacidad adaptativa en finca
    vulnerabilidad_aheladas_finca = finca.base.data
    vulnerabilidad_aheladas_finca$vulnerabilidad = ifelse(capaciadadaptativa.aheladas.finca$finca.tabla.capsens == 0,sensibilidad.aheladas.finca/0.0012, sensibilidad.aheladas.finca / capaciadadaptativa.aheladas.finca$finca.tabla.capsens)
    #comparacion finca provincia
    vulnerabilidad_aheladas_finca$vulnerabilidad.n01 = finca.n01_function(vulnerabilidad_aheladas_finca,vulnerabilidad_aheladas_data,
                                                                          finca_provincia,"vulnerabilidad")

    #4.6 INDICE RIESGO CLIMATICO HELADAS
    columnas_riesgoclimatico_aheladas_data = c("DPA_DESPRO","DPA_DESPAR")
    riesgoclimatico_aheladas_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_riesgoclimatico_aheladas_data] #construccion de la tabla con las columnas q intervienen
    riesgoclimatico_aheladas_data$amenaza = amenaza_aheladas_data$Heladas_parr.N01
    riesgoclimatico_aheladas_data$exposicion = variable.n01_function(exposicion_aheladas_data,"Exposicion.pasto....")
    riesgoclimatico_aheladas_data$vulnerabilidad = variable.n01_function(vulnerabilidad_aheladas_data,"vulnerabilidad")

    # Calculo del riesgo climatico en la provincia
    riesgoclimatico_aheladas_data$riesgoclimatico = (riesgoclimatico_aheladas_data$amenaza*
                                                       riesgoclimatico_aheladas_data$exposicion*
                                                       riesgoclimatico_aheladas_data$vulnerabilidad)^(1/3)

    riesgoclimatico_aheladas_data$riesgoclimatico.n01 = variable.n01_function(riesgoclimatico_aheladas_data,
                                                                              "riesgoclimatico")

    # Calculo del riesgo climatico en finca
    riesgoclimatico_aheladas_finca = finca.base.data
    riesgoclimatico_aheladas_finca$riesgoclimatico = ifelse((amenaza_aheladas_finca*
                                                               riesgoclimatico_aheladas_finca$Exposicion.pasto.....n01*
                                                               vulnerabilidad_aheladas_finca$vulnerabilidad.n01)< 0,0,
                                                            (amenaza_aheladas_finca*
                                                               riesgoclimatico_aheladas_finca$Exposicion.pasto.....n01*
                                                               vulnerabilidad_aheladas_finca$vulnerabilidad.n01)^(1/3))

    riesgoclimatico_aheladas_finca$riesgoclimatico.n01 = finca.n01_function(riesgoclimatico_aheladas_finca,
                                                                            riesgoclimatico_aheladas_data,
                                                                            finca_provincia,"riesgoclimatico")

    #4.7 RESULTADOS
    aheladas.amenaza.finca = amenaza_aheladas_finca
    aheladas.amenaza.parroquia = riesgoclimatico_aheladas_data[riesgoclimatico_aheladas_data$DPA_DESPAR==finca_parroquia,"amenaza"]

    aheladas.exposicion.finca = riesgoclimatico_aheladas_finca$Exposicion.pasto.....n01
    aheladas.exposicion.parroquia = riesgoclimatico_aheladas_data[riesgoclimatico_aheladas_data$DPA_DESPAR==finca_parroquia,"exposicion"]

    aheladas.sensibilidad.finca = sensibilidad.aheladas.finca
    aheladas.sensibilidad.parroquia = sensibilidad.aheladas.finca

    aheladas.capacidadadaptativa.finca = capaciadadaptativa.aheladas.finca$finca.tabla.capsens
    aheladas.capacidadadaptativa.parroquia = capaciadadaptativa.aheladas.finca$parroquia.tabla.capsens

    aheladas.vulnerabilidad.finca = vulnerabilidad_aheladas_finca$vulnerabilidad.n01
    aheladas.vulnerabilidad.parroquia = riesgoclimatico_aheladas_data[riesgoclimatico_aheladas_data$DPA_DESPAR==finca_parroquia,"vulnerabilidad"]

    aheladas.riesgoclimatico.finca = riesgoclimatico_aheladas_finca$riesgoclimatico.n01
    aheladas.riesgoclimatico.parroquia = riesgoclimatico_aheladas_data[riesgoclimatico_aheladas_data$DPA_DESPAR==finca_parroquia,"riesgoclimatico.n01"]

    #==========================================
    #5. AMBIENTAL LLUVIAS
    #==========================================
    
    #5.1 AMENAZA TENDENCIA LLUVIAS
    amenaza.alluvias.lista.provincia = c("ACTUAL.Amenaza.Tendencia.Lluvias_parr")
    columnas_amenaza_alluvias_data = c("DPA_DESPRO","DPA_DESPAR",amenaza.alluvias.lista.provincia) # columnas de la base provincial que intervienen en amenaza LLUVIAS
    amenaza_alluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_amenaza_alluvias_data] #construccion de la base adicional
    amenaza_alluvias_data$Lluvias_parr.N01<- variable.n01_function(amenaza_alluvias_data,"ACTUAL.Amenaza.Tendencia.Lluvias_parr")
    amenaza_alluvias_finca = amenaza_alluvias_data[amenaza_alluvias_data$DPA_DESPAR==finca_parroquia,"Lluvias_parr.N01"]
    
    #5.2 EXPOSICION TENDENCIA LLUVIAS
    #Ver 3.2 exposicion pastos
    exposicion_alluvias_data = exposicion_asequia_data
    
    #5.3 SENSIBILIDAD LLUVIAS
    finca.sensibilidad.alluvias.lista= c("Carga.Animal")
    provincia.sensibilidad.alluvias.lista = c("capacidad.de.uso.de.la.tierra_parr..SEN1.", "Degradacion_parr","Carga.Animal", "Porc_inund")
    columnas_sensibilidad_alluvias_data = c("DPA_DESPRO","DPA_DESPAR",provincia.sensibilidad.alluvias.lista) #columnas de sensibilidad
    sensibilidad_alluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_sensibilidad_alluvias_data] #construccion de la tabla con las columnas q intervienen
    #calculo de carga animal provincia y finca
    #ver 3.3
    sensibilidad.alluvias.finca = finca.capsens(sensibilidad_alluvias_data,finca_provincia, 
                                                provincia.sensibilidad.alluvias.lista,finca_parroquia,finca.sensibilidad.alluvias.lista,
                                                finca.base.data)
    sensibilidad.alluvias.provincia = finca.capsens(sensibilidad_alluvias_data,finca_provincia, 
                                                    provincia.sensibilidad.alluvias.lista)
    
    
    #5.4 CAPACIDAD ADAPTATIVA LLUVIAS
    
    #finca.base.data$Infraestructura.multiproposito_riego = Infraestructura.multiproposito_riego_coeficiente_sequia
    finca.base.data$Infraestructura.multiproposito_riego = Infraestructura.multiproposito_riego_coeficiente_lluvias
    
    finca.capaciadadaptativa.alluvias.lista= c("Infraestructura.multiproposito_riego",
                                               "Porc_Cobert_Nat",
                                               "Presencia.de.sociobosque....")
    provincia.capaciadadaptativa.alluvias.lista = c("Infraestructura.multiproposito_riego",
                                                    "Porc_Cobert_Nat",
                                                    "Velocidad.Infiltracion",
                                                    "Presencia.de.sociobosque....")
    columnas_capaciadadaptativa_alluvias_data = c("DPA_DESPRO","DPA_DESPAR",provincia.capaciadadaptativa.alluvias.lista)
    capaciadadaptativa_alluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_capaciadadaptativa_alluvias_data] #construccion de la tabla con las columnas q intervienen
    
    #calculo de variables a nivel de finca
    #Porc_Cobert_Nat finca ver 4.2
    capaciadadaptativa.alluvias.finca = finca.capsens(capaciadadaptativa_alluvias_data,finca_provincia, 
                                                      provincia.capaciadadaptativa.alluvias.lista,finca_parroquia,finca.capaciadadaptativa.alluvias.lista,
                                                      finca.base.data)
    capaciadadaptativa.alluvias.provincia = finca.capsens(capaciadadaptativa_alluvias_data,finca_provincia, 
                                                          provincia.capaciadadaptativa.alluvias.lista)
    
    #5.5 INDICE VULNERABILIDAD LLUVIAS
    columnas_vulnerabilidad_alluvias_data = c("DPA_DESPRO","DPA_DESPAR")
    vulnerabilidad_alluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_vulnerabilidad_alluvias_data] #construccion de la tabla con las columnas q intervienen
    vulnerabilidad_alluvias_data$sensibilidad = sensibilidad.alluvias.provincia$tabla.capsens$capsens
    vulnerabilidad_alluvias_data$capacidad.adaptativa = capaciadadaptativa.alluvias.provincia$tabla.capsens$capsens
    
    # Calculo de la capacidad adaptativa en la provincia
    vulnerabilidad_alluvias_data$vulnerabilidad = ifelse(vulnerabilidad_alluvias_data$capacidad.adaptativa==0,vulnerabilidad_alluvias_data$sensibilidad/0.0012, vulnerabilidad_alluvias_data$sensibilidad/vulnerabilidad_alluvias_data$capacidad.adaptativa)
    # Calculo de la capacidad adaptativa en finca
    vulnerabilidad_alluvias_finca = finca.base.data
    # cuando la capacidad apadptativa es cero, se le asigna el valor de 0.0012, que es el valor mas bajo del estudio
    vulnerabilidad_alluvias_finca$vulnerabilidad = ifelse(capaciadadaptativa.alluvias.finca$finca.tabla.capsens==0,sensibilidad.alluvias.finca$finca.tabla.capsens / 0.0012, sensibilidad.alluvias.finca$finca.tabla.capsens / capaciadadaptativa.alluvias.finca$finca.tabla.capsens)
    #comparacion finca provincia
    vulnerabilidad_alluvias_finca$vulnerabilidad.n01 = finca.n01_function(vulnerabilidad_alluvias_finca,vulnerabilidad_alluvias_data,
                                                                          finca_provincia,"vulnerabilidad")
    
    #5.6 INDICE RIESGO CLIMATICO LLUVIAS
    columnas_riesgoclimatico_alluvias_data = c("DPA_DESPRO","DPA_DESPAR")
    riesgoclimatico_alluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_riesgoclimatico_alluvias_data] #construccion de la tabla con las columnas q intervienen
    riesgoclimatico_alluvias_data$amenaza = amenaza_alluvias_data$Lluvias_parr.N01
    riesgoclimatico_alluvias_data$exposicion = variable.n01_function(exposicion_alluvias_data,"Exposicion.pasto....")
    riesgoclimatico_alluvias_data$vulnerabilidad = variable.n01_function(vulnerabilidad_alluvias_data,"vulnerabilidad")
    
    # Calculo del riesgo climatico en la provincia
    riesgoclimatico_alluvias_data$riesgoclimatico = (riesgoclimatico_alluvias_data$amenaza*
                                                       riesgoclimatico_alluvias_data$exposicion*
                                                       riesgoclimatico_alluvias_data$vulnerabilidad)^(1/3)
    
    riesgoclimatico_alluvias_data$riesgoclimatico.n01 = variable.n01_function(riesgoclimatico_alluvias_data,
                                                                              "riesgoclimatico")
    
    # Calculo del riesgo climatico en finca
    riesgoclimatico_alluvias_finca = finca.base.data
    riesgoclimatico_alluvias_finca$riesgoclimatico = ifelse((amenaza_alluvias_finca*
                                                               riesgoclimatico_alluvias_finca$Exposicion.pasto.....n01*
                                                               vulnerabilidad_alluvias_finca$vulnerabilidad.n01)< 0,0,
                                                            (amenaza_alluvias_finca*
                                                               riesgoclimatico_alluvias_finca$Exposicion.pasto.....n01*
                                                               vulnerabilidad_alluvias_finca$vulnerabilidad.n01)^(1/3))
    
    riesgoclimatico_alluvias_finca$riesgoclimatico.n01 = finca.n01_function(riesgoclimatico_alluvias_finca,
                                                                            riesgoclimatico_alluvias_data,
                                                                            finca_provincia,"riesgoclimatico")
    
    #5.7 RESULTADOS
    alluvias.amenaza.finca = amenaza_alluvias_finca
    alluvias.amenaza.parroquia = riesgoclimatico_alluvias_data[riesgoclimatico_alluvias_data$DPA_DESPAR==finca_parroquia,"amenaza"]
    
    alluvias.exposicion.finca = riesgoclimatico_alluvias_finca$Exposicion.pasto.....n01
    alluvias.exposicion.parroquia = riesgoclimatico_alluvias_data[riesgoclimatico_alluvias_data$DPA_DESPAR==finca_parroquia,"exposicion"]
    
    alluvias.sensibilidad.finca = sensibilidad.alluvias.finca$finca.tabla.capsens
    alluvias.sensibilidad.parroquia = sensibilidad.alluvias.finca$parroquia.tabla.capsens
    
    alluvias.capacidadadaptativa.finca = capaciadadaptativa.alluvias.finca$finca.tabla.capsens
    alluvias.capacidadadaptativa.parroquia = capaciadadaptativa.alluvias.finca$parroquia.tabla.capsens
    
    alluvias.vulnerabilidad.finca = vulnerabilidad_alluvias_finca$vulnerabilidad.n01
    alluvias.vulnerabilidad.parroquia = riesgoclimatico_alluvias_data[riesgoclimatico_alluvias_data$DPA_DESPAR==finca_parroquia,"vulnerabilidad"]
    
    alluvias.riesgoclimatico.finca = riesgoclimatico_alluvias_finca$riesgoclimatico.n01
    alluvias.riesgoclimatico.parroquia = riesgoclimatico_alluvias_data[riesgoclimatico_alluvias_data$DPA_DESPAR==finca_parroquia,"riesgoclimatico.n01"]
    
    
    #==========================================
    #SOCIOECONOMICO
    #==========================================
    
    
    #6. SOCIOECONOMICO SEQUIA
    #==========================================
    
    #6.1 AMENAZA TENDENCIA SEQUIA
    #VER 3.1
    #amenaza_asequia_data$Amenaza.Tendencia.asequia.n01 
    #amenaza_asequia_finca
    amenaza_ssequia_data = amenaza_asequia_data
    amenaza_ssequia_finca = amenaza_asequia_finca
    
    #6.2 EXPOSICION TENDENCIA SEQUIA
    exposicion.ssequia.lista.provincia = c("Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores..")
    columnas_exposicion_ssequia_data = c("DPA_DESPRO","DPA_DESPAR",exposicion.ssequia.lista.provincia) #columnas de exposicion
    exposicion_ssequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_exposicion_ssequia_data] #construccion de la tabla con las columnas q intervienen
    
    #calculo de exposicion en finca
    finca.base.data$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores.. = finca.base.data$UBAS # calculo de exposicion en finca
    
    
    temp.tabla = data.frame()
    tabla.provincia = exposicion_ssequia_data
    for (i in 1:nrow(tabla.provincia)) {
      if (tabla.provincia[i,"DPA_DESPRO"] == finca_provincia) { #aseguramos que se toman todos los datos de la provincia correspondiente
        temp.tabla <- rbind(temp.tabla,tabla.provincia[i,])
      }
    }
    #Evaluamos el dato de finca:
    #si es cero, se asigna cero al nuevo valor
    #caso contario se aplica la formula: (valor finca - mininimo provincia)/(maximo provincia - minimo provincia)
    finca.columna_a_evaluar = "Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores.."
    maxmin=max(temp.tabla[,finca.columna_a_evaluar]) - min(temp.tabla[,finca.columna_a_evaluar])
    if(maxmin==0){
      maxmin1=finca.base.data[,finca.columna_a_evaluar]
    } else{
      maxmin1=maxmin
    }
    
    tabla.finca = finca.base.data
    #si el valor es menor al minimo de la provincia, se asigna cero. Si es mayor al maximo de la provincia, se asigna 1
    tabla.finca <- transform(tabla.finca, nueva_columna = ifelse(tabla.finca[,finca.columna_a_evaluar] == 0, 0, 
                                                                 ifelse(tabla.finca[,finca.columna_a_evaluar] <=  min(temp.tabla[,finca.columna_a_evaluar]), 1,
                                                                        ifelse(tabla.finca[,finca.columna_a_evaluar] >=  max(temp.tabla[,finca.columna_a_evaluar]), 0,
                                                                               (max(temp.tabla[,finca.columna_a_evaluar]-tabla.finca[,finca.columna_a_evaluar]))/
                                                                                 (maxmin1)))))
    finca.base.data$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01 <- tabla.finca[,"nueva_columna"]
    
    
    max(temp.tabla[,"Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores.."])
    
    
    #6.3 SENSIBILIDAD SEQUIA
    
    finca.sensibilidad.ssequia.lista= c("Carga.Animal","Conflicto.gente.fauna")
    provincia.sensibilidad.ssequia.lista = c("Conflicto.gente.fauna", "X..Poblacion.migrante.masc", "Carga.Animal",
                                             "X..poblacion.dedicada.a.agri.y.gan.", "Nivel.de.pobreza.por.consumo", 
                                             "Tasa.de.dependencia.por.edad","Tasa.de.analfabetismo.funcional" )
    
    columnas_sensibilidad_ssequia_data = c("DPA_DESPRO","DPA_DESPAR",provincia.sensibilidad.ssequia.lista) #columnas de sensibilidad
    sensibilidad_ssequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_sensibilidad_ssequia_data] #construccion de la tabla con las columnas q intervienen
    
    #calculo de carga animal finca
    #Ver 3.3
    
    sensibilidad.ssequia.finca = finca.capsens(sensibilidad_ssequia_data,finca_provincia, 
                                               provincia.sensibilidad.ssequia.lista,finca_parroquia,finca.sensibilidad.ssequia.lista,
                                               finca.base.data)
    sensibilidad.ssequia.provincia = finca.capsens(sensibilidad_ssequia_data,finca_provincia, 
                                                   provincia.sensibilidad.ssequia.lista)
    
    #6.4 CAPACIDAD ADAPTATIVA SEQUIA
    finca.capaciadadaptativa.ssequia.lista= c("Porc_riego",
                                              "Indice.de.red.hidrica",
                                              "Porc_Cobert_Nat",
                                              "Herramientas.de.planificacion.CC",
                                              "Estimado.de.volumen.de.credito",
                                              "Sistemas.productivos.pecuarios")
    
    provincia.capaciadadaptativa.ssequia.lista = c("Indice.de.red.hidrica", 
                                                   "Porc_riego",
                                                   "Porc_Cobert_Nat",
                                                   "Indice.de.red.vial",
                                                   "Herramientas.de.planificacion.CC", 
                                                   "Cobertura.movil.por.parroquia",
                                                   "Estimado.de.volumen.de.credito", 
                                                   "Sistemas.productivos.pecuarios")
    
    columnas_capaciadadaptativa_ssequia_data = c("DPA_DESPRO","DPA_DESPAR",provincia.capaciadadaptativa.ssequia.lista)
    capaciadadaptativa_ssequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_capaciadadaptativa_ssequia_data] #construccion de la tabla con las columnas q intervienen
    #calculo de variables a nivel de finca
    #porc.riego ver 3.4
    #indice.red.hidrica ver 3.4
    #porc.cobert.nat ver 3.4
    finca.base.data$Porc_Cobert_Nat = cobertura_vegetacion_natural_socioeconomico  
    
    
    tabla.provincias = capaciadadaptativa_ssequia_data
    nombre.provincia = finca_provincia
    lista.variables.provincia = provincia.capaciadadaptativa.ssequia.lista
    nombre.parroquia = finca_parroquia
    lista.variables.finca = finca.capaciadadaptativa.ssequia.lista
    finca.tabla = finca.base.data
    
    temp.tabla = data.frame()
    for (i in 1:nrow(tabla.provincias)) {
      if (tabla.provincias[i,"DPA_DESPRO"] == nombre.provincia) {
        temp.tabla <- rbind(temp.tabla,tabla.provincias[i,])
      }
    }
    w.indice.capsens = 0 #desviacion estandar acumulada de todas las variables 
    sqr.dataframe = data.frame() # lista de desviaciones estandar por cada variable
    
    for(i in lista.variables.provincia){
      #se normaliza de cero a uno utilizando la funcion variable.n01_function de todas las variables que intervienen
      #se acumula en temp.table los resultados de cada variable con nombre de la variable terminado en "n.01"
      temp.tabla[,paste(i,".n01",sep = "")] <- variable.n01_function(temp.tabla,i)
      var.i = varianza(temp.tabla[,paste(i,".n01",sep="")])
      sqr.i = var.i^(1/2)
      sqr.dataframe = c(sqr.dataframe, sqr.i)
      w.indice.capsens = w.indice.capsens+sqr.i
    }
    #fraccion que representa cada desviacion estandar en relacion a la desviacion estandar acumulada
    w.dataframe = data.frame()
    for (i in sqr.dataframe) {
      w.i = ifelse(w.indice.capsens==0,0, i/w.indice.capsens)
      w.dataframe = c(w.dataframe,w.i)
    }
    #generamos una columna para realizar el calculo de capacidad adaptativa o sensibilidad
    temp.tabla = transform(temp.tabla,nueva_columna = 0)
    listavariables.capsens = double() #lista que acumulara todas los datos de todas las variables que conforman el calculo
    for (i in 1:length(lista.variables.provincia)) {
      #Se calcula multiplicando cada valor de la variable normalizada con su peso respectivo
      temp.tabla = transform(temp.tabla,nueva_columna = nueva_columna +
                               temp.tabla[,paste(lista.variables.provincia[[i]],".n01",sep = "")]*w.dataframe[[i]])
      #se acumula cada dato en una lista
      listavariables.capsens = c(listavariables.capsens, temp.tabla[,paste(lista.variables.provincia[[i]],".n01",sep = "")])
    }
    #cambiamos el nombre de la columna por "capsens" 
    colnames(temp.tabla)[ colnames(temp.tabla) == "nueva_columna" ] <- "capsens"
    #generamos los quantiles en la lista de datos de las variables
    quantiles.indice.capsens = quantiles_function(listavariables.capsens)
    
    #extrae el dato de capsens de la parroquia desde temp.table
    parroquia.capsens = temp.tabla[temp.tabla$DPA_DESPAR == nombre.parroquia,]$capsens
    #se extrae el numero de fila de los datos de la parroquia desde matriz de datos de temp.tabla
    finca.row.number = which(temp.tabla$DPA_DESPAR==nombre.parroquia & temp.tabla$DPA_DESPRO==nombre.provincia)
    #se genera una matriz con los datos de la parroquia desde temp.table, esta incluye todas las variables por defecto
    #de la parroquia a la cual pertenece la finca
    finca.base = temp.tabla[finca.row.number,]
    for (i in lista.variables.finca) {
      
      #se normaliza el dato de parroquia con la funcion finca.n01_function, en relacion al dato provincial
      finca.base[,paste(i,".n01",sep = "")] <- finca.n01_function(finca.tabla,temp.tabla,finca_provincia,i)
      #se adiciona los datos de cada variable a los datos de finca
      finca.base[,i] = finca.tabla[,i]
    }
    finca.base$Estimado.de.volumen.de.credito.n01 = finca.n01_function(finca.tabla,base_credito,finca_provincia,
                                                                       "Estimado.de.volumen.de.credito")
    
    #se genera una columna para el calculo de sensibilidad o capacidad adaptativa a nivel de finca
    finca.tabla = transform(finca.tabla,nueva_columna = 0)
    #se calcula utilizando los datos de finca.base que incluye cada variable de la finca, multiplicando por el peso
    #provincial calculado previamente
    for (i in 1:length(lista.variables.provincia)) {
      finca.tabla = transform(finca.tabla,nueva_columna = nueva_columna +
                                finca.base[,paste(lista.variables.provincia[[i]],".n01",sep = "")]*w.dataframe[[i]])
    }
    #cambio de nombre de la nueva columna
    colnames(finca.tabla)[ colnames(finca.tabla) == "nueva_columna" ] <- "capsens"
    
    capaciadadaptativa.ssequia.finca = list(finca.tabla.capsens = finca.tabla$capsens, parroquia.tabla.capsens = parroquia.capsens,
                                            quantiles.resultados = quantiles.indice.capsens, datos.variables = listavariables.capsens)
    
    capaciadadaptativa.ssequia.provincia = finca.capsens(capaciadadaptativa_ssequia_data,finca_provincia, 
                                                         provincia.capaciadadaptativa.ssequia.lista)
    
    #6.5 INDICE VULNERABILIDAD SEQUIA
    columnas_vulnerabilidad_ssequia_data = c("DPA_DESPRO","DPA_DESPAR")
    vulnerabilidad_ssequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_vulnerabilidad_ssequia_data] #construccion de la tabla con las columnas q intervienen
    vulnerabilidad_ssequia_data$sensibilidad = sensibilidad.ssequia.provincia$tabla.capsens$capsens
    vulnerabilidad_ssequia_data$capacidad.adaptativa = capaciadadaptativa.ssequia.provincia$tabla.capsens$capsens
    
    # Calculo de la capacidad adaptativa en la provincia
    vulnerabilidad_ssequia_data$vulnerabilidad = ifelse(vulnerabilidad_ssequia_data$capacidad.adaptativa==0,vulnerabilidad_ssequia_data$sensibilidad/0.0012, vulnerabilidad_ssequia_data$sensibilidad/vulnerabilidad_ssequia_data$capacidad.adaptativa)
    # Calculo de la capacidad adaptativa en finca
    vulnerabilidad_ssequia_finca = finca.base.data
    # cuando la capacidad apadptativa es cero, se le asigna el valor de 0.0012, que es el valor mas bajo del estudio
    vulnerabilidad_ssequia_finca$vulnerabilidad = ifelse(capaciadadaptativa.ssequia.finca$finca.tabla.capsens==0,sensibilidad.ssequia.finca$finca.tabla.capsens / 0.0012, sensibilidad.ssequia.finca$finca.tabla.capsens/capaciadadaptativa.ssequia.finca$finca.tabla.capsens)
    #comparacion finca provincia
    vulnerabilidad_ssequia_finca$vulnerabilidad.n01 = finca.n01_function(vulnerabilidad_ssequia_finca,vulnerabilidad_ssequia_data,
                                                                         finca_provincia,"vulnerabilidad")
    
    #6.6 INDICE RIESGO CLIMATICO SEQUIA
    columnas_riesgoclimatico_ssequia_data = c("DPA_DESPRO","DPA_DESPAR")
    riesgoclimatico_ssequia_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_riesgoclimatico_ssequia_data] #construccion de la tabla con las columnas q intervienen
    riesgoclimatico_ssequia_data$amenaza = amenaza_ssequia_data$Amenaza.Tendencia.asequia.n01
    riesgoclimatico_ssequia_data$exposicion = variable.n01_function(exposicion_ssequia_data,"Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores..",inverse_data = TRUE)
    riesgoclimatico_ssequia_data$vulnerabilidad = variable.n01_function(vulnerabilidad_ssequia_data,"vulnerabilidad")
    
    # Calculo de la capacidad adaptativa en la provincia
    riesgoclimatico_ssequia_data$riesgoclimatico = (riesgoclimatico_ssequia_data$amenaza*
                                                      riesgoclimatico_ssequia_data$exposicion*
                                                      riesgoclimatico_ssequia_data$vulnerabilidad)^(1/3)
    
    riesgoclimatico_ssequia_data$riesgoclimatico.n01 = variable.n01_function(riesgoclimatico_ssequia_data,
                                                                             "riesgoclimatico")
    
    # Calculo de la capacidad adaptativa en finca
    riesgoclimatico_ssequia_finca = finca.base.data
    riesgoclimatico_ssequia_finca$riesgoclimatico = ifelse((amenaza_ssequia_finca*
                                                              riesgoclimatico_ssequia_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01*
                                                              vulnerabilidad_ssequia_finca$vulnerabilidad.n01)< 0,0,
                                                           (amenaza_ssequia_finca*
                                                              riesgoclimatico_ssequia_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01*
                                                              vulnerabilidad_ssequia_finca$vulnerabilidad.n01)^(1/3))
    
    riesgoclimatico_ssequia_finca$riesgoclimatico.n01 = finca.n01_function(riesgoclimatico_ssequia_finca,
                                                                           riesgoclimatico_ssequia_data,
                                                                           finca_provincia,"riesgoclimatico")
    
    #6.7 RESULTADOS
    ssequia.amenaza.finca = amenaza_ssequia_finca
    ssequia.amenaza.parroquia = riesgoclimatico_ssequia_data[riesgoclimatico_ssequia_data$DPA_DESPAR==finca_parroquia,"amenaza"]
    
    ssequia.exposicion.finca = riesgoclimatico_ssequia_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01
    ssequia.exposicion.parroquia = riesgoclimatico_ssequia_data[riesgoclimatico_ssequia_data$DPA_DESPAR==finca_parroquia,"exposicion"]
    
    ssequia.sensibilidad.finca = sensibilidad.ssequia.finca$finca.tabla.capsens
    ssequia.sensibilidad.parroquia = sensibilidad.ssequia.finca$parroquia.tabla.capsens
    
    ssequia.capacidadadaptativa.finca = capaciadadaptativa.ssequia.finca$finca.tabla.capsens
    ssequia.capacidadadaptativa.parroquia = capaciadadaptativa.ssequia.finca$parroquia.tabla.capsens
    
    ssequia.vulnerabilidad.finca = vulnerabilidad_ssequia_finca$vulnerabilidad.n01
    ssequia.vulnerabilidad.parroquia = riesgoclimatico_ssequia_data[riesgoclimatico_ssequia_data$DPA_DESPAR==finca_parroquia,"vulnerabilidad"]
    
    ssequia.riesgoclimatico.finca = riesgoclimatico_ssequia_finca$riesgoclimatico.n01
    ssequia.riesgoclimatico.parroquia = riesgoclimatico_ssequia_data[riesgoclimatico_ssequia_data$DPA_DESPAR==finca_parroquia,"riesgoclimatico.n01"]
    
    
    #7. SOCIOECONOMICO LLUVIA
    #==========================================
    
    #7.1 AMENAZA TENDENCIA LLUVIA
    #VER 3.1
    #amenaza_asequia_data$Amenaza.Tendencia.asequia.n01 
    #amenaza_asequia_finca
    amenaza_slluvias_data = amenaza_alluvias_data
    amenaza_slluvias_finca = amenaza_alluvias_finca
    
    #7.2 EXPOSICION TENDENCIA LLUVIA
    exposicion_slluvias_data = exposicion_ssequia_data
    #calculo de exposicion en finca
    #ver 6.1
    
    #7.3 SENSIBILIDAD LLUVIA
    finca.sensibilidad.slluvias.lista= c("Carga.Animal")
    provincia.sensibilidad.slluvias.lista = c("Porc_inund","Deficit.habitacional.cualitativo","X..Poblacion.migrante.masc",
                                              "Carga.Animal","X..poblacion.dedicada.a.agri.y.gan.", "Nivel.de.pobreza.por.consumo",
                                              "Tasa.de.dependencia.por.edad","Tasa.de.analfabetismo.funcional" )
    
    columnas_sensibilidad_slluvias_data = c("DPA_DESPRO","DPA_DESPAR",provincia.sensibilidad.slluvias.lista) #columnas de sensibilidad
    sensibilidad_slluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_sensibilidad_slluvias_data] #construccion de la tabla con las columnas q intervienen
    
    #calculo de carga animal finca
    #Ver 3.3
    
    sensibilidad.slluvias.finca = finca.capsens(sensibilidad_slluvias_data,finca_provincia, 
                                                provincia.sensibilidad.slluvias.lista,finca_parroquia,finca.sensibilidad.slluvias.lista,
                                                finca.base.data)
    sensibilidad.slluvias.provincia = finca.capsens(sensibilidad_slluvias_data,finca_provincia, 
                                                    provincia.sensibilidad.slluvias.lista)
    
    #7.4 CAPACIDAD ADAPTATIVA LLUVIA
    
    #finca.base.data$Infraestructura.multiproposito_riego = Infraestructura.multiproposito_riego_coeficiente_sequia
    finca.base.data$Infraestructura.multiproposito_riego = Infraestructura.multiproposito_riego_coeficiente_lluvias
    
    finca.capaciadadaptativa.slluvias.lista= c("Infraestructura.multiproposito_riego",
                                               "Porc_Cobert_Nat",
                                               "Herramientas.de.planificacion.CC",
                                               "Disponibilidad.de.pronostico.del.clima",
                                               "Sistemas.productivos.pecuarios")
    
    provincia.capaciadadaptativa.slluvias.lista = c("Infraestructura.multiproposito_riego",
                                                    "Porc_Cobert_Nat",
                                                    "Indice.de.red.vial",
                                                    "Herramientas.de.planificacion.CC", 
                                                    "Cobertura.movil.por.parroquia",
                                                    "Disponibilidad.de.pronostico.del.clima",
                                                    "Sistemas.productivos.pecuarios")
    
    columnas_capaciadadaptativa_slluvias_data = c("DPA_DESPRO","DPA_DESPAR",provincia.capaciadadaptativa.slluvias.lista)
    capaciadadaptativa_slluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_capaciadadaptativa_slluvias_data] #construccion de la tabla con las columnas q intervienen
    #calculo de variables a nivel de finca
    #infraestructura.multiproposito_riego ver 3.4
    #porc.cobert.nat ver 3.4
    #Herramientas.de.planificacion.CC ver 6.4
    #Sistemas.productivos.pecuarios ver 6.4
    capaciadadaptativa.slluvias.finca = finca.capsens(capaciadadaptativa_slluvias_data,finca_provincia, 
                                                      provincia.capaciadadaptativa.slluvias.lista,finca_parroquia,finca.capaciadadaptativa.slluvias.lista,
                                                      finca.base.data)
    capaciadadaptativa.slluvias.provincia = finca.capsens(capaciadadaptativa_slluvias_data,finca_provincia, 
                                                          provincia.capaciadadaptativa.slluvias.lista)
    
    #7.5 INDICE VULNERABILIDAD LLUVIA
    columnas_vulnerabilidad_slluvias_data = c("DPA_DESPRO","DPA_DESPAR")
    vulnerabilidad_slluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_vulnerabilidad_slluvias_data] #construccion de la tabla con las columnas q intervienen
    vulnerabilidad_slluvias_data$sensibilidad = sensibilidad.slluvias.provincia$tabla.capsens$capsens
    vulnerabilidad_slluvias_data$capacidad.adaptativa = capaciadadaptativa.slluvias.provincia$tabla.capsens$capsens
    
    # Calculo de la capacidad adaptativa en la provincia
    vulnerabilidad_slluvias_data$vulnerabilidad = ifelse(vulnerabilidad_slluvias_data$capacidad.adaptativa==0,vulnerabilidad_slluvias_data$sensibilidad/0.0012, vulnerabilidad_slluvias_data$sensibilidad/vulnerabilidad_slluvias_data$capacidad.adaptativa)
    # Calculo de la capacidad adaptativa en finca
    vulnerabilidad_slluvias_finca = finca.base.data
    # cuando la capacidad apadptativa es cero, se le asigna el valor de 0.0012, que es el valor mas bajo del estudio
    vulnerabilidad_slluvias_finca$vulnerabilidad = ifelse(capaciadadaptativa.slluvias.finca$finca.tabla.capsens==0,sensibilidad.slluvias.finca$finca.tabla.capsens / 0.0012, sensibilidad.slluvias.finca$finca.tabla.capsens/capaciadadaptativa.slluvias.finca$finca.tabla.capsens)
    #comparacion finca provincia
    vulnerabilidad_slluvias_finca$vulnerabilidad.n01 = finca.n01_function(vulnerabilidad_slluvias_finca,vulnerabilidad_slluvias_data,
                                                                          finca_provincia,"vulnerabilidad")
    
    #7.6 INDICE RIESGO CLIMATICO LLUVIA
    columnas_riesgoclimatico_slluvias_data = c("DPA_DESPRO","DPA_DESPAR")
    riesgoclimatico_slluvias_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_riesgoclimatico_slluvias_data] #construccion de la tabla con las columnas q intervienen
    riesgoclimatico_slluvias_data$amenaza = amenaza_slluvias_data$Lluvias_parr.N01
    riesgoclimatico_slluvias_data$exposicion = variable.n01_function(exposicion_slluvias_data,"Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores..",inverse_data = TRUE)
    riesgoclimatico_slluvias_data$vulnerabilidad = variable.n01_function(vulnerabilidad_slluvias_data,"vulnerabilidad")
    
    # Calculo de la capacidad adaptativa en la provincia
    riesgoclimatico_slluvias_data$riesgoclimatico = (riesgoclimatico_slluvias_data$amenaza*
                                                       riesgoclimatico_slluvias_data$exposicion*
                                                       riesgoclimatico_slluvias_data$vulnerabilidad)^(1/3)
    
    riesgoclimatico_slluvias_data$riesgoclimatico.n01 = variable.n01_function(riesgoclimatico_slluvias_data,
                                                                              "riesgoclimatico")
    
    # Calculo de la capacidad adaptativa en finca
    riesgoclimatico_slluvias_finca = finca.base.data
    riesgoclimatico_slluvias_finca$riesgoclimatico = ifelse((amenaza_slluvias_finca*
                                                               riesgoclimatico_slluvias_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01*
                                                               vulnerabilidad_slluvias_finca$vulnerabilidad.n01)< 0,0,
                                                            (amenaza_slluvias_finca*
                                                               riesgoclimatico_slluvias_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01*
                                                               vulnerabilidad_slluvias_finca$vulnerabilidad.n01)^(1/3))
    
    riesgoclimatico_slluvias_finca$riesgoclimatico.n01 = finca.n01_function(riesgoclimatico_slluvias_finca,
                                                                            riesgoclimatico_slluvias_data,
                                                                            finca_provincia,"riesgoclimatico")
    
    
    #7.7 RESULTADOS
    slluvias.amenaza.finca = amenaza_slluvias_finca
    slluvias.amenaza.parroquia = riesgoclimatico_slluvias_data[riesgoclimatico_slluvias_data$DPA_DESPAR==finca_parroquia,"amenaza"]
    
    slluvias.exposicion.finca = riesgoclimatico_slluvias_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01
    slluvias.exposicion.parroquia = riesgoclimatico_slluvias_data[riesgoclimatico_slluvias_data$DPA_DESPAR==finca_parroquia,"exposicion"]
    
    slluvias.sensibilidad.finca = sensibilidad.slluvias.finca$finca.tabla.capsens
    slluvias.sensibilidad.parroquia = sensibilidad.slluvias.finca$parroquia.tabla.capsens
    
    slluvias.capacidadadaptativa.finca = capaciadadaptativa.slluvias.finca$finca.tabla.capsens
    slluvias.capacidadadaptativa.parroquia = capaciadadaptativa.slluvias.finca$parroquia.tabla.capsens
    
    slluvias.vulnerabilidad.finca = vulnerabilidad_slluvias_finca$vulnerabilidad.n01
    slluvias.vulnerabilidad.parroquia = riesgoclimatico_slluvias_data[riesgoclimatico_slluvias_data$DPA_DESPAR==finca_parroquia,"vulnerabilidad"]
    
    slluvias.riesgoclimatico.finca = riesgoclimatico_slluvias_finca$riesgoclimatico.n01
    slluvias.riesgoclimatico.parroquia = riesgoclimatico_slluvias_data[riesgoclimatico_slluvias_data$DPA_DESPAR==finca_parroquia,"riesgoclimatico.n01"]
    
    
    #8. SOCIOECONOMICO OLAS DE CALOR
    #==========================================
    
    #8.1 AMENAZA TENDENCIA OLAS DE CALOR
    amenaza.solasdecalor.lista.provincia = c("ACTUAL.Tendencia.OlasCalor_parr")
    columnas_amenaza_solasdecalor_data = c("DPA_DESPRO","DPA_DESPAR",amenaza.solasdecalor.lista.provincia) # columnas de la base provincial que intervienen en amenaza HELADAS
    amenaza_solasdecalor_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_amenaza_solasdecalor_data] #construccion de la base adicional
    amenaza_solasdecalor_data$olasdecalor_parr.N01<- variable.n01_function(amenaza_solasdecalor_data,"ACTUAL.Tendencia.OlasCalor_parr")
    amenaza_solasdecalor_finca = amenaza_solasdecalor_data[amenaza_solasdecalor_data$DPA_DESPAR==finca_parroquia,"olasdecalor_parr.N01"]
    
    #8.2 EXPOSICION TENDENCIA OLAS DE CALOR
    exposicion_solasdecalor_data = exposicion_ssequia_data
    #calculo de exposicion en finca
    #ver 6.1
    
    #8.3 SENSIBILIDAD OLAS DE CALOR
    finca.sensibilidad.solasdecalor.lista= c("Carga.Animal")
    provincia.sensibilidad.solasdecalor.lista = c("Carga.Animal","Nivel.de.pobreza.por.consumo")
    
    columnas_sensibilidad_solasdecalor_data = c("DPA_DESPRO","DPA_DESPAR",provincia.sensibilidad.solasdecalor.lista) #columnas de sensibilidad
    sensibilidad_solasdecalor_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_sensibilidad_solasdecalor_data] #construccion de la tabla con las columnas q intervienen
    
    #calculo de carga animal finca
    #Ver 3.3
    
    sensibilidad.solasdecalor.finca = finca.capsens(sensibilidad_solasdecalor_data,finca_provincia, 
                                                    provincia.sensibilidad.solasdecalor.lista,finca_parroquia,finca.sensibilidad.solasdecalor.lista,
                                                    finca.base.data)
    sensibilidad.solasdecalor.provincia = finca.capsens(sensibilidad_solasdecalor_data,finca_provincia, 
                                                        provincia.sensibilidad.solasdecalor.lista)
    
    #8.4 CAPACIDAD ADAPTATIVA OLAS DE CALOR
    finca.capaciadadaptativa.solasdecalor.lista= c("Porc_riego",
                                                   "Indice.de.red.hidrica",
                                                   "Porc_Cobert_Nat",
                                                   "Disponibilidad.de.pronostico.del.clima",
                                                   "Herramientas.de.planificacion.CC",
                                                   "Sistemas.productivos.pecuarios")
    
    provincia.capaciadadaptativa.solasdecalor.lista = c("Porc_riego", "Porc_Cobert_Nat","Indice.de.red.hidrica",
                                                        "Herramientas.de.planificacion.CC", "Cobertura.movil.por.parroquia",
                                                        "Disponibilidad.de.pronostico.del.clima","Sistemas.productivos.pecuarios")
    
    columnas_capaciadadaptativa_solasdecalor_data = c("DPA_DESPRO","DPA_DESPAR",provincia.capaciadadaptativa.solasdecalor.lista)
    capaciadadaptativa_solasdecalor_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_capaciadadaptativa_solasdecalor_data] #construccion de la tabla con las columnas q intervienen
    #calculo de variables a nivel de finca
    #porc.cobert.nat ver 3.4
    #Sistemas.productivos.pecuarios ver 6.4
    
    capaciadadaptativa.solasdecalor.finca = finca.capsens(capaciadadaptativa_solasdecalor_data,finca_provincia, 
                                                          provincia.capaciadadaptativa.solasdecalor.lista,finca_parroquia,finca.capaciadadaptativa.solasdecalor.lista,
                                                          finca.base.data)
    capaciadadaptativa.solasdecalor.provincia = finca.capsens(capaciadadaptativa_solasdecalor_data,finca_provincia, 
                                                              provincia.capaciadadaptativa.solasdecalor.lista)
    
    #8.5 INDICE VULNERABILIDAD OLAS DE CALOR
    columnas_vulnerabilidad_solasdecalor_data = c("DPA_DESPRO","DPA_DESPAR")
    vulnerabilidad_solasdecalor_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_vulnerabilidad_solasdecalor_data] #construccion de la tabla con las columnas q intervienen
    vulnerabilidad_solasdecalor_data$sensibilidad = sensibilidad.solasdecalor.provincia$tabla.capsens$capsens
    vulnerabilidad_solasdecalor_data$capacidad.adaptativa = capaciadadaptativa.solasdecalor.provincia$tabla.capsens$capsens
    
    # Calculo de la capacidad adaptativa en la provincia
    vulnerabilidad_solasdecalor_data$vulnerabilidad = ifelse(vulnerabilidad_solasdecalor_data$capacidad.adaptativa==0,vulnerabilidad_solasdecalor_data$sensibilidad/0.0012, vulnerabilidad_solasdecalor_data$sensibilidad/vulnerabilidad_solasdecalor_data$capacidad.adaptativa)
    # Calculo de la capacidad adaptativa en finca
    vulnerabilidad_solasdecalor_finca = finca.base.data
    # cuando la capacidad apadptativa es cero, se le asigna el valor de 0.0012, que es el valor mas bajo del estudio
    vulnerabilidad_solasdecalor_finca$vulnerabilidad = ifelse(capaciadadaptativa.solasdecalor.finca$finca.tabla.capsens==0,sensibilidad.solasdecalor.finca$finca.tabla.capsens / 0.0012, sensibilidad.solasdecalor.finca$finca.tabla.capsens/capaciadadaptativa.solasdecalor.finca$finca.tabla.capsens)
    #comparacion finca provincia
    vulnerabilidad_solasdecalor_finca$vulnerabilidad.n01 = finca.n01_function(vulnerabilidad_solasdecalor_finca,vulnerabilidad_solasdecalor_data,
                                                                              finca_provincia,"vulnerabilidad")
    
    #8.6 INDICE RIESGO CLIMATICO OLAS DE CALOR
    columnas_riesgoclimatico_solasdecalor_data = c("DPA_DESPRO","DPA_DESPAR")
    riesgoclimatico_solasdecalor_data = base_data[base_data$DPA_DESPRO==finca_provincia,columnas_riesgoclimatico_solasdecalor_data] #construccion de la tabla con las columnas q intervienen
    riesgoclimatico_solasdecalor_data$amenaza = amenaza_solasdecalor_data$olasdecalor_parr.N01
    riesgoclimatico_solasdecalor_data$exposicion = variable.n01_function(exposicion_solasdecalor_data,"Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores..",inverse_data = TRUE)
    riesgoclimatico_solasdecalor_data$vulnerabilidad = variable.n01_function(vulnerabilidad_solasdecalor_data,"vulnerabilidad")
    
    # Calculo de la capacidad adaptativa en la provincia
    riesgoclimatico_solasdecalor_data$riesgoclimatico = (riesgoclimatico_solasdecalor_data$amenaza*
                                                           riesgoclimatico_solasdecalor_data$exposicion*
                                                           riesgoclimatico_solasdecalor_data$vulnerabilidad)^(1/3)
    
    riesgoclimatico_solasdecalor_data$riesgoclimatico.n01 = variable.n01_function(riesgoclimatico_solasdecalor_data,
                                                                                  "riesgoclimatico")
    
    # Calculo de la capacidad adaptativa en finca
    riesgoclimatico_solasdecalor_finca = finca.base.data
    riesgoclimatico_solasdecalor_finca$riesgoclimatico = ifelse((amenaza_slluvias_finca*
                                                                   riesgoclimatico_slluvias_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01*
                                                                   vulnerabilidad_slluvias_finca$vulnerabilidad.n01)< 0,0,
                                                                (amenaza_solasdecalor_finca*
                                                                   riesgoclimatico_solasdecalor_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01*
                                                                   vulnerabilidad_solasdecalor_finca$vulnerabilidad.n01)^(1/3))
    
    riesgoclimatico_solasdecalor_finca$riesgoclimatico.n01 = finca.n01_function(riesgoclimatico_solasdecalor_finca,
                                                                                riesgoclimatico_solasdecalor_data,
                                                                                finca_provincia,"riesgoclimatico")
    
    #8.7 RESULTADOS
    solasdecalor.amenaza.finca = amenaza_solasdecalor_finca
    solasdecalor.amenaza.parroquia = riesgoclimatico_solasdecalor_data[riesgoclimatico_solasdecalor_data$DPA_DESPAR==finca_parroquia,"amenaza"]
    
    solasdecalor.exposicion.finca = riesgoclimatico_solasdecalor_finca$Indice.de.tenencia..numero.de.cabezas.de.ganado.numero.de.productores...n01
    solasdecalor.exposicion.parroquia = riesgoclimatico_solasdecalor_data[riesgoclimatico_solasdecalor_data$DPA_DESPAR==finca_parroquia,"exposicion"]
    
    solasdecalor.sensibilidad.finca = sensibilidad.solasdecalor.finca$finca.tabla.capsens
    solasdecalor.sensibilidad.parroquia = sensibilidad.solasdecalor.finca$parroquia.tabla.capsens
    
    solasdecalor.capacidadadaptativa.finca = capaciadadaptativa.solasdecalor.finca$finca.tabla.capsens
    solasdecalor.capacidadadaptativa.parroquia = capaciadadaptativa.solasdecalor.finca$parroquia.tabla.capsens
    
    solasdecalor.vulnerabilidad.finca = vulnerabilidad_solasdecalor_finca$vulnerabilidad.n01
    solasdecalor.vulnerabilidad.parroquia = riesgoclimatico_solasdecalor_data[riesgoclimatico_solasdecalor_data$DPA_DESPAR==finca_parroquia,"vulnerabilidad"]
    
    solasdecalor.riesgoclimatico.finca = riesgoclimatico_solasdecalor_finca$riesgoclimatico.n01
    solasdecalor.riesgoclimatico.parroquia = riesgoclimatico_solasdecalor_data[riesgoclimatico_solasdecalor_data$DPA_DESPAR==finca_parroquia,"riesgoclimatico.n01"]
    
    
    #############################################################
    ## RESULTS
    #############################################################
    
    #QUATILES ASEQUIA
    quantiles_riesgoclimatico_asequia = quantiles_function(c(riesgoclimatico_asequia_data$amenaza,
                                                             riesgoclimatico_asequia_data$exposicion,
                                                             riesgoclimatico_asequia_data$vulnerabilidad))
    
    quantiles_vulnerabilidad_asequia = finca.capsens(base_data,
                                                     finca_provincia, 
                                                     c(provincia.sensibilidad.asequia.lista,
                                                       provincia.capaciadadaptativa.asequia.lista))$quantiles.resultados
    
    quantiles_capacidadadaptativa_asequia = capaciadadaptativa.asequia.provincia$quantiles.resultados
    
    quantiles_sensibilidad_asequia = sensibilidad.asequia.provincia$quantiles.resultados
    
    
    #QUATILES AHELADAS
    quantiles_riesgoclimatico_aheladas = quantiles_function(c(riesgoclimatico_aheladas_data$amenaza,
                                                              riesgoclimatico_aheladas_data$exposicion,
                                                              riesgoclimatico_aheladas_data$vulnerabilidad))
    
    quantiles_vulnerabilidad_aheladas = finca.capsens(base_data,
                                                      finca_provincia, 
                                                      c(provincia.sensibilidad.aheladas.lista,
                                                        provincia.capaciadadaptativa.aheladas.lista))$quantiles.resultados
    
    quantiles_capacidadadaptativa_aheladas = capaciadadaptativa.aheladas.provincia$quantiles.resultados
    
    quantiles_sensibilidad_aheladas = sensibilidad.aheladas.provincia$quantiles.resultados
    
    
    #QUATILES ALLUVIAS
    quantiles_riesgoclimatico_alluvias = quantiles_function(c(riesgoclimatico_alluvias_data$amenaza,
                                                              riesgoclimatico_alluvias_data$exposicion,
                                                              riesgoclimatico_alluvias_data$vulnerabilidad))
    
    quantiles_vulnerabilidad_alluvias = finca.capsens(base_data,
                                                      finca_provincia, 
                                                      c(provincia.sensibilidad.alluvias.lista,
                                                        provincia.capaciadadaptativa.alluvias.lista))$quantiles.resultados
    
    quantiles_capacidadadaptativa_alluvias = capaciadadaptativa.alluvias.provincia$quantiles.resultados
    
    quantiles_sensibilidad_alluvias = sensibilidad.alluvias.provincia$quantiles.resultados
    
    
    #QUATILES SSEQUIA
    quantiles_riesgoclimatico_ssequia = quantiles_function(c(riesgoclimatico_ssequia_data$amenaza,
                                                             riesgoclimatico_ssequia_data$exposicion,
                                                             riesgoclimatico_ssequia_data$vulnerabilidad))
    
    quantiles_vulnerabilidad_ssequia = finca.capsens(base_data,
                                                     finca_provincia, 
                                                     c(provincia.sensibilidad.ssequia.lista,
                                                       provincia.capaciadadaptativa.ssequia.lista))$quantiles.resultados
    
    quantiles_capacidadadaptativa_ssequia = capaciadadaptativa.ssequia.provincia$quantiles.resultados
    
    quantiles_sensibilidad_ssequia = sensibilidad.ssequia.provincia$quantiles.resultados
    
    
    #QUATILES SLLUVIAS
    quantiles_riesgoclimatico_slluvias = quantiles_function(c(riesgoclimatico_slluvias_data$amenaza,
                                                              riesgoclimatico_slluvias_data$exposicion,
                                                              riesgoclimatico_slluvias_data$vulnerabilidad))
    
    quantiles_vulnerabilidad_slluvias = finca.capsens(base_data,
                                                      finca_provincia, 
                                                      c(provincia.sensibilidad.slluvias.lista,
                                                        provincia.capaciadadaptativa.slluvias.lista))$quantiles.resultados
    
    quantiles_capacidadadaptativa_slluvias = capaciadadaptativa.slluvias.provincia$quantiles.resultados
    
    quantiles_sensibilidad_slluvias = sensibilidad.slluvias.provincia$quantiles.resultados
    
    
    #QUATILES SOLASDECALOR
    quantiles_riesgoclimatico_solasdecalor = quantiles_function(c(riesgoclimatico_solasdecalor_data$amenaza,
                                                                  riesgoclimatico_solasdecalor_data$exposicion,
                                                                  riesgoclimatico_solasdecalor_data$vulnerabilidad))
    
    quantiles_vulnerabilidad_solasdecalor = finca.capsens(base_data,
                                                          finca_provincia, 
                                                          c(provincia.sensibilidad.solasdecalor.lista,
                                                            provincia.capaciadadaptativa.solasdecalor.lista))$quantiles.resultados
    
    quantiles_capacidadadaptativa_solasdecalor = capaciadadaptativa.solasdecalor.provincia$quantiles.resultados
    
    quantiles_sensibilidad_solasdecalor = sensibilidad.solasdecalor.provincia$quantiles.resultados
    
    
    
    #RESULTADOS FINALES
    print_table = data.frame()
    
    print_table["capacidad_adaptativa_ambiental_sequia", "finca"] = asequia.capacidadadaptativa.finca
    print_table["capacidad_adaptativa_ambiental_sequia", "finca 1-5"] = calificar_quantiles_function(
      asequia.capacidadadaptativa.finca,
      quantiles_capacidadadaptativa_asequia)
    print_table["capacidad_adaptativa_ambiental_sequia", "parroquia"] = asequia.capacidadadaptativa.parroquia
    print_table["capacidad_adaptativa_ambiental_sequia", "parroquia 1-5"] = calificar_quantiles_function(
      asequia.capacidadadaptativa.parroquia,
      quantiles_capacidadadaptativa_asequia)
    
    print_table["sensibilidad_ambiental_sequia", "finca"] = asequia.sensibilidad.finca
    print_table["sensibilidad_ambiental_sequia", "finca 1-5"] = calificar_quantiles_function(
      asequia.sensibilidad.finca,
      quantiles_sensibilidad_asequia)
    print_table["sensibilidad_ambiental_sequia", "parroquia"] = asequia.sensibilidad.parroquia
    print_table["sensibilidad_ambiental_sequia", "parroquia 1-5"] = calificar_quantiles_function(
      asequia.sensibilidad.parroquia,
      quantiles_sensibilidad_asequia)
    
    print_table["vulnerabilidad_ambiental_sequia", "finca"] = asequia.vulnerabilidad.finca
    print_table["vulnerabilidad_ambiental_sequia", "finca 1-5"] = calificar_quantiles_function(
      asequia.vulnerabilidad.finca,
      quantiles_vulnerabilidad_asequia)
    print_table["vulnerabilidad_ambiental_sequia", "parroquia"] = asequia.vulnerabilidad.parroquia
    print_table["vulnerabilidad_ambiental_sequia", "parroquia 1-5"] = calificar_quantiles_function(
      asequia.vulnerabilidad.parroquia,
      quantiles_vulnerabilidad_asequia)
    
    print_table["riesgo_climatico_ambiental_sequia", "finca"] = asequia.riesgoclimatico.finca
    print_table["riesgo_climatico_ambiental_sequia", "finca 1-5"] = calificar_quantiles_function(
      asequia.riesgoclimatico.finca,
      quantiles_riesgoclimatico_asequia)
    print_table["riesgo_climatico_ambiental_sequia", "parroquia"] = asequia.riesgoclimatico.parroquia
    print_table["riesgo_climatico_ambiental_sequia", "parroquia 1-5"] = calificar_quantiles_function(
      asequia.riesgoclimatico.parroquia,
      quantiles_riesgoclimatico_asequia)
    
   
    print_table["capacidad_adaptativa_ambiental_heladas", "finca"] = aheladas.capacidadadaptativa.finca
    print_table["capacidad_adaptativa_ambiental_heladas", "finca 1-5"] = calificar_quantiles_function(
      aheladas.capacidadadaptativa.finca,
      quantiles_capacidadadaptativa_aheladas)
    print_table["capacidad_adaptativa_ambiental_heladas", "parroquia"] = aheladas.capacidadadaptativa.parroquia
    print_table["capacidad_adaptativa_ambiental_heladas", "parroquia 1-5"] = calificar_quantiles_function(
      aheladas.capacidadadaptativa.parroquia,
      quantiles_capacidadadaptativa_aheladas)
    
    print_table["sensibilidad_ambiental_heladas", "finca"] = aheladas.sensibilidad.finca
    print_table["sensibilidad_ambiental_heladas", "finca 1-5"] = calificar_quantiles_function(
      aheladas.sensibilidad.finca,
      quantiles_sensibilidad_aheladas)
    print_table["sensibilidad_ambiental_heladas", "parroquia"] = aheladas.sensibilidad.parroquia
    print_table["sensibilidad_ambiental_heladas", "parroquia 1-5"] = calificar_quantiles_function(
      aheladas.sensibilidad.parroquia,
      quantiles_sensibilidad_aheladas)
    
    print_table["vulnerabilidad_ambiental_heladas", "finca"] = aheladas.vulnerabilidad.finca
    print_table["vulnerabilidad_ambiental_heladas", "finca 1-5"] = calificar_quantiles_function(
      aheladas.vulnerabilidad.finca,
      quantiles_vulnerabilidad_aheladas)
    print_table["vulnerabilidad_ambiental_heladas", "parroquia"] = aheladas.vulnerabilidad.parroquia
    print_table["vulnerabilidad_ambiental_heladas", "parroquia 1-5"] = calificar_quantiles_function(
      aheladas.vulnerabilidad.parroquia,
      quantiles_vulnerabilidad_aheladas)
    
    print_table["riesgo_climatico_ambiental_heladas", "finca"] = aheladas.riesgoclimatico.finca
    print_table["riesgo_climatico_ambiental_heladas", "finca 1-5"] = calificar_quantiles_function(
      aheladas.riesgoclimatico.finca,
      quantiles_riesgoclimatico_aheladas)
    print_table["riesgo_climatico_ambiental_heladas", "parroquia"] = aheladas.riesgoclimatico.parroquia
    print_table["riesgo_climatico_ambiental_heladas", "parroquia 1-5"] = calificar_quantiles_function(
      aheladas.riesgoclimatico.parroquia,
      quantiles_riesgoclimatico_aheladas)
    
    
    print_table["capacidad_adaptativa_ambiental_lluvias", "finca"] = alluvias.capacidadadaptativa.finca
    print_table["capacidad_adaptativa_ambiental_lluvias", "finca 1-5"] = calificar_quantiles_function(
      alluvias.capacidadadaptativa.finca,
      quantiles_capacidadadaptativa_alluvias)
    print_table["capacidad_adaptativa_ambiental_lluvias", "parroquia"] = alluvias.capacidadadaptativa.parroquia
    print_table["capacidad_adaptativa_ambiental_lluvias", "parroquia 1-5"] = calificar_quantiles_function(
      alluvias.capacidadadaptativa.parroquia,
      quantiles_capacidadadaptativa_alluvias)
    
    print_table["sensibilidad_ambiental_lluvias", "finca"] = alluvias.sensibilidad.finca
    print_table["sensibilidad_ambiental_lluvias", "finca 1-5"] = calificar_quantiles_function(
      alluvias.sensibilidad.finca,
      quantiles_sensibilidad_alluvias)
    print_table["sensibilidad_ambiental_lluvias", "parroquia"] = alluvias.sensibilidad.parroquia
    print_table["sensibilidad_ambiental_lluvias", "parroquia 1-5"] = calificar_quantiles_function(
      alluvias.sensibilidad.parroquia,
      quantiles_sensibilidad_alluvias)
    
    print_table["vulnerabilidad_ambiental_lluvias", "finca"] = alluvias.vulnerabilidad.finca
    print_table["vulnerabilidad_ambiental_lluvias", "finca 1-5"] = calificar_quantiles_function(
      alluvias.vulnerabilidad.finca,
      quantiles_vulnerabilidad_alluvias)
    print_table["vulnerabilidad_ambiental_lluvias", "parroquia"] = alluvias.vulnerabilidad.parroquia
    print_table["vulnerabilidad_ambiental_lluvias", "parroquia 1-5"] = calificar_quantiles_function(
      alluvias.vulnerabilidad.parroquia,
      quantiles_vulnerabilidad_alluvias)
    
    print_table["riesgo_climatico_ambiental_lluvias", "finca"] = alluvias.riesgoclimatico.finca
    print_table["riesgo_climatico_ambiental_lluvias", "finca 1-5"] = calificar_quantiles_function(
      alluvias.riesgoclimatico.finca,
      quantiles_riesgoclimatico_alluvias)
    print_table["riesgo_climatico_ambiental_lluvias", "parroquia"] = alluvias.riesgoclimatico.parroquia
    print_table["riesgo_climatico_ambiental_lluvias", "parroquia 1-5"] = calificar_quantiles_function(
      alluvias.riesgoclimatico.parroquia,
      quantiles_riesgoclimatico_alluvias)
    
    print_table["capacidad_adaptativa_socioeconomico_sequia", "finca"] = ssequia.capacidadadaptativa.finca
    print_table["capacidad_adaptativa_socioeconomico_sequia", "finca 1-5"] = calificar_quantiles_function(
      ssequia.capacidadadaptativa.finca,
      quantiles_capacidadadaptativa_ssequia)
    print_table["capacidad_adaptativa_socioeconomico_sequia", "parroquia"] = ssequia.capacidadadaptativa.parroquia
    print_table["capacidad_adaptativa_socioeconomico_sequia", "parroquia 1-5"] = calificar_quantiles_function(
      ssequia.capacidadadaptativa.parroquia,
      quantiles_capacidadadaptativa_ssequia)
    
    print_table["sensibilidad_socioeconomico_sequia", "finca"] = ssequia.sensibilidad.finca
    print_table["sensibilidad_socioeconomico_sequia", "finca 1-5"] = calificar_quantiles_function(
      ssequia.sensibilidad.finca,
      quantiles_sensibilidad_ssequia)
    print_table["sensibilidad_socioeconomico_sequia", "parroquia"] = ssequia.sensibilidad.parroquia
    print_table["sensibilidad_socioeconomico_sequia", "parroquia 1-5"] = calificar_quantiles_function(
      ssequia.sensibilidad.parroquia,
      quantiles_sensibilidad_ssequia)
    
    print_table["vulnerabilidad_socioeconomico_sequia", "finca"] = ssequia.vulnerabilidad.finca
    print_table["vulnerabilidad_socioeconomico_sequia", "finca 1-5"] = calificar_quantiles_function(
      ssequia.vulnerabilidad.finca,
      quantiles_vulnerabilidad_ssequia)
    print_table["vulnerabilidad_socioeconomico_sequia", "parroquia"] = ssequia.vulnerabilidad.parroquia
    print_table["vulnerabilidad_socioeconomico_sequia", "parroquia 1-5"] = calificar_quantiles_function(
      ssequia.vulnerabilidad.parroquia,
      quantiles_vulnerabilidad_ssequia)
    
    print_table["riesgo_climatico_socioeconomico_sequia", "finca"] = ssequia.riesgoclimatico.finca
    print_table["riesgo_climatico_socioeconomico_sequia", "finca 1-5"] = calificar_quantiles_function(
      ssequia.riesgoclimatico.finca,
      quantiles_riesgoclimatico_ssequia)
    print_table["riesgo_climatico_socioeconomico_sequia", "parroquia"] = ssequia.riesgoclimatico.parroquia
    print_table["riesgo_climatico_socioeconomico_sequia", "parroquia 1-5"] = calificar_quantiles_function(
      ssequia.riesgoclimatico.parroquia,
      quantiles_riesgoclimatico_ssequia)
    
    
    print_table["capacidad_adaptativa_socioeconomico_lluvias", "finca"] = slluvias.capacidadadaptativa.finca
    print_table["capacidad_adaptativa_socioeconomico_lluvias", "finca 1-5"] = calificar_quantiles_function(
      slluvias.capacidadadaptativa.finca,
      quantiles_capacidadadaptativa_slluvias)
    print_table["capacidad_adaptativa_socioeconomico_lluvias", "parroquia"] = slluvias.capacidadadaptativa.parroquia
    print_table["capacidad_adaptativa_socioeconomico_lluvias", "parroquia 1-5"] = calificar_quantiles_function(
      slluvias.capacidadadaptativa.parroquia,
      quantiles_capacidadadaptativa_slluvias)
    
    print_table["sensibilidad_socioeconomico_lluvias", "finca"] = slluvias.sensibilidad.finca
    print_table["sensibilidad_socioeconomico_lluvias", "finca 1-5"] = calificar_quantiles_function(
      slluvias.sensibilidad.finca,
      quantiles_sensibilidad_slluvias)
    print_table["sensibilidad_socioeconomico_lluvias", "parroquia"] = slluvias.sensibilidad.parroquia
    print_table["sensibilidad_socioeconomico_lluvias", "parroquia 1-5"] = calificar_quantiles_function(
      slluvias.sensibilidad.parroquia,
      quantiles_sensibilidad_slluvias)
    
    print_table["vulnerabilidad_socioeconomico_lluvias", "finca"] = slluvias.vulnerabilidad.finca
    print_table["vulnerabilidad_socioeconomico_lluvias", "finca 1-5"] = calificar_quantiles_function(
      slluvias.vulnerabilidad.finca,
      quantiles_vulnerabilidad_slluvias)
    print_table["vulnerabilidad_socioeconomico_lluvias", "parroquia"] = slluvias.vulnerabilidad.parroquia
    print_table["vulnerabilidad_socioeconomico_lluvias", "parroquia 1-5"] = calificar_quantiles_function(
      slluvias.vulnerabilidad.parroquia,
      quantiles_vulnerabilidad_slluvias)
    
    print_table["riesgo_climatico_socioeconomico_lluvias", "finca"] = slluvias.riesgoclimatico.finca
    print_table["riesgo_climatico_socioeconomico_lluvias", "finca 1-5"] = calificar_quantiles_function(
      slluvias.riesgoclimatico.finca,
      quantiles_riesgoclimatico_slluvias)
    print_table["riesgo_climatico_socioeconomico_lluvias", "parroquia"] = slluvias.riesgoclimatico.parroquia
    print_table["riesgo_climatico_socioeconomico_lluvias", "parroquia 1-5"] = calificar_quantiles_function(
      slluvias.riesgoclimatico.parroquia,
      quantiles_riesgoclimatico_slluvias)
    
    
    print_table["capacidad_adaptativa_socioeconomico_olasdecalor", "finca"] = solasdecalor.capacidadadaptativa.finca
    print_table["capacidad_adaptativa_socioeconomico_olasdecalor", "finca 1-5"] = calificar_quantiles_function(
      solasdecalor.capacidadadaptativa.finca,
      quantiles_capacidadadaptativa_solasdecalor)
    print_table["capacidad_adaptativa_socioeconomico_olasdecalor", "parroquia"] = solasdecalor.capacidadadaptativa.parroquia
    print_table["capacidad_adaptativa_socioeconomico_olasdecalor", "parroquia 1-5"] = calificar_quantiles_function(
      solasdecalor.capacidadadaptativa.parroquia,
      quantiles_capacidadadaptativa_solasdecalor)
    
    print_table["sensibilidad_socioeconomico_olasdecalor", "finca"] = solasdecalor.sensibilidad.finca
    print_table["sensibilidad_socioeconomico_olasdecalor", "finca 1-5"] = calificar_quantiles_function(
      solasdecalor.sensibilidad.finca,
      quantiles_sensibilidad_solasdecalor)
    print_table["sensibilidad_socioeconomico_olasdecalor", "parroquia"] = solasdecalor.sensibilidad.parroquia
    print_table["sensibilidad_socioeconomico_olasdecalor", "parroquia 1-5"] = calificar_quantiles_function(
      solasdecalor.sensibilidad.parroquia,
      quantiles_sensibilidad_solasdecalor)
    
    print_table["vulnerabilidad_socioeconomico_olasdecalor", "finca"] = solasdecalor.vulnerabilidad.finca
    print_table["vulnerabilidad_socioeconomico_olasdecalor", "finca 1-5"] = calificar_quantiles_function(
      solasdecalor.vulnerabilidad.finca,
      quantiles_vulnerabilidad_solasdecalor)
    print_table["vulnerabilidad_socioeconomico_olasdecalor", "parroquia"] = solasdecalor.vulnerabilidad.parroquia
    print_table["vulnerabilidad_socioeconomico_olasdecalor", "parroquia 1-5"] = calificar_quantiles_function(
      solasdecalor.vulnerabilidad.parroquia,
      quantiles_vulnerabilidad_solasdecalor)
    
    print_table["riesgo_climatico_socioeconomico_olasdecalor", "finca"] = solasdecalor.riesgoclimatico.finca
    print_table["riesgo_climatico_socioeconomico_olasdecalor", "finca 1-5"] = calificar_quantiles_function(
      solasdecalor.riesgoclimatico.finca,
      quantiles_riesgoclimatico_solasdecalor)
    print_table["riesgo_climatico_socioeconomico_olasdecalor", "parroquia"] = solasdecalor.riesgoclimatico.parroquia
    print_table["riesgo_climatico_socioeconomico_olasdecalor", "parroquia 1-5"] = calificar_quantiles_function(
      solasdecalor.riesgoclimatico.parroquia,
      quantiles_riesgoclimatico_solasdecalor)
    
    
    write.csv(print_table, file = paste(dir_folder,"/",nombre_productor,".csv", sep = ""))
  }
  
}
