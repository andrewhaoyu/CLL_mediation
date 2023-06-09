args = commandArgs(trailingOnly = T)
i1 = as.numeric(args[[1]])
#goal: mediation analyses for cll projects
setwd("/data/zhangh24/CLL_mediation/")
source("./code/MedFun.R")
library(survival)
library(mediation)
library(data.table)
library(dplyr)
#load data with 436784 subjects
data = readRDS("./data/mediation1.rds")
#data = readRDS("./data/mediation_prscomp_chip.rds")
#436361 controls, 423 cases
#remove 2241 subjects (2236 controls, 5 cases) with missing smoking status
data = data %>% filter(smoke_NFC!=9)
#create data matrix for the smoking status
smoke_bin = model.matrix(~as.factor(smoke_NFC), data = data)[,-1]
colnames(smoke_bin) = c("Former", "Current")
data = cbind(data,smoke_bin)
#load prs file
prs = fread("./data/CLL_PRS_info/CLL_score.profile")
#finalized data: 434125 controls, 418 cases
data_com = left_join(data,prs, by = c("f.eid"="IID"))
data_com_control = data_com[data_com$case_control_cancer_control==0,]
mean_prs = mean(data_com_control$SCORESUM,na.rm = T)
se_prs = sd(data_com_control$SCORESUM,na.rm = T)
data_com$SCORESUM_sd = (data_com$SCORESUM-mean_prs)/se_prs
#variable_list
var_list = c("YRI_scale","ASN_scale","Former","Current","white_blood_cell_count",
             "monocyte_percentage","neutrophil_percentage",
             "autosome_mosaic","ch_chip","lymphoid","myeloid","lymphoid_chip",
             "myeloid_chip","both","lymphoid_myeloid")
#binary variable uses logistic regression
bin_var = c("Former","Current","autosome_mosaic","ch_chip","lymphoid","myeloid","lymphoid_chip",
            "myeloid_chip","both","lymphoid_myeloid")
#continuous variable uses linear regression
med_var_name = var_list[i1]
med_var = data_com[,med_var_name,drop=F]
colnames(med_var) = c("med_var")
data_clean = cbind(data_com,med_var)


#fit the mediator model
if(med_var_name%in%bin_var){
  #separate different exiting covariates
  if(med_var_name=="Former"){
    med_model = glm(med_var ~ SCORESUM_sd + age + age2 + YRI_scale + ASN_scale  + Current + sex_new + white_blood_cell_count, 
                    data = data_clean,
                    family = "binomial")
  }else if(med_var_name=="Current"){
    med_model = glm(med_var ~ SCORESUM_sd + age + age2 + YRI_scale + ASN_scale  + Former + sex_new + white_blood_cell_count, 
                    data = data_clean,
                    family = "binomial")
  }else{
    med_model = glm(med_var ~ SCORESUM_sd + age + age2 + YRI_scale + ASN_scale  + Former + Current + sex_new + white_blood_cell_count, 
                    data = data_clean,
                    family = "binomial")
  }
  
}else{
  #separate different exiting covariates
  if(med_var_name=="YRI_scale"){
    med_model = lm(med_var ~ SCORESUM_sd + age + age2  + ASN_scale  + Former + Current + sex_new + white_blood_cell_count, 
                    data = data_clean)
  }else if(med_var_name=="ASN_scale"){
    med_model = lm(med_var ~ SCORESUM_sd + age + age2 + YRI_scale + ASN_scale  + Former + Current + sex_new + white_blood_cell_count, 
                    data = data_clean)
  }else if(med_var_name=="white_blood_cell_count"){
    med_model = lm(med_var ~ SCORESUM_sd + age + age2 + YRI_scale + ASN_scale  + Former + Current + sex_new, 
                   data = data_clean)
  }else{
    med_model = lm(med_var ~ SCORESUM_sd + age + age2 + YRI_scale + ASN_scale  + Former + Current + sex_new + white_blood_cell_count, 
                    data = data_clean)
  }
}
#fit the output model
if(med_var_name=="Former"){
  out_model = glm(case_control_cancer_ignore~SCORESUM_sd + med_var + age + age2 + YRI_scale + ASN_scale + Current + sex_new + white_blood_cell_count, 
                  data = data_clean,
                  family = "binomial")
  
}else if(med_var_name=="Current"){
  out_model = glm(case_control_cancer_ignore~SCORESUM_sd + med_var + age + age2 + YRI_scale + ASN_scale + Former + sex_new + white_blood_cell_count, 
                  data = data_clean,
                  family = "binomial")
}else if(med_var_name=="YRI_scale"){
  out_model = glm(case_control_cancer_ignore~SCORESUM_sd + med_var + age + age2 + ASN_scale + Former + Current + sex_new + white_blood_cell_count, 
                  data = data_clean,
                  family = "binomial")
}else if(med_var_name=="ASN_scale"){
  out_model = glm(case_control_cancer_ignore~SCORESUM_sd + med_var + age + age2 + YRI_scale + Former + Current + sex_new + white_blood_cell_count, 
                  data = data_clean,
                  family = "binomial")
}else if(med_var_name=="white_blood_cell_count"){
  out_model = glm(case_control_cancer_ignore~SCORESUM_sd + med_var + age + age2 + YRI_scale + ASN_scale + Former + Current + sex_new, 
                  data = data_clean,
                  family = "binomial")
  
}else{
  out_model = glm(case_control_cancer_ignore~SCORESUM_sd + med_var + age + age2 + YRI_scale + ASN_scale + Former + Current + sex_new + white_blood_cell_count, 
                  data = data_clean,
                  family = "binomial")
  
}

#set up the baseline value for other covariates
if(med_var_name=="Former"){
  C = c(mean(data_clean$age), mean(data_clean$age2), mean(data_clean$YRI_scale),  
        mean(data_clean$ASN_scale), 0, 0, mean(data_clean$white_blood_cell_count,na.rm = T))
  
  
}else if(med_var_name=="Current"){
  C = c(mean(data_clean$age), mean(data_clean$age2), mean(data_clean$YRI_scale),  
        mean(data_clean$ASN_scale), 0, 0, mean(data_clean$white_blood_cell_count,na.rm = T))
  
}else if(med_var_name=="YRI_scale"){
  C = c(mean(data_clean$age), mean(data_clean$age2), 
        mean(data_clean$ASN_scale), 0, 0, 0, mean(data_clean$white_blood_cell_count,na.rm = T))
  
}else if(med_var_name=="ASN_scale"){
  C = c(mean(data_clean$age), mean(data_clean$age2), mean(data_clean$YRI_scale),  
        0, 0, 0, mean(data_clean$white_blood_cell_count,na.rm = T))
  
}else if(med_var_name=="white_blood_cell_count"){
  C = c(mean(data_clean$age), mean(data_clean$age2), mean(data_clean$YRI_scale),  
        mean(data_clean$ASN_scale), 0, 0, 0,na.rm = T)
  
}else{
  C = c(mean(data_clean$age), mean(data_clean$age2), mean(data_clean$YRI_scale),  
        mean(data_clean$ASN_scale), 0, 0, 0, mean(data_clean$white_blood_cell_count,na.rm = T))
  
  
}

if(med_var_name%in%bin_var){
  #binary mediator binary outcome
  result = MediationBB(out_model,med_model, A0 = 0, A1 = 1,C = C, M = NULL, Interaction = NULL)  
}else{
  #continous mediator binary outcome
  result = MediationCB(out_model,med_model, A0 = 0, A1 = 1,C = C, M = NULL, Interaction = NULL)  
}


Mediation = function(out_model, med_model){
  out_coef = coefficients(summary(out_model))
  log_NDE = out_coef[2,1]
  log_NDE_se = out_coef[2,2]
  NDE_p = out_coef[2,4]
  OR_NDE = exp(log_NDE)
  OR_NDE_low = exp(log_NDE-1.96*log_NDE_se)
  OR_NDE_high = exp(log_NDE+1.96*log_NDE_se)
  med_coef = coefficients(summary(med_model))
  log_NIE = out_coef[3,1]*med_coef[2,1]
  log_NIE_se = sqrt(out_coef[3,1]^2*med_coef[2,2]^2+
                      med_coef[2,1]^2*out_coef[3,2]^2)
  NIE_p = 2*pnorm(-abs(log_NIE/log_NIE_se), lower.tail = T)
  OR_NIE = exp(log_NIE)
  OR_NIE_low = exp(log_NIE-1.96*log_NIE_se)
  OR_NIE_high = exp(log_NIE+1.96*log_NIE_se)
  total_coef = coefficients(summary(total_model))
  log_TE = log_NDE + log_NIE
  log_TE_se = sqrt(log_NDE_se^2+log_NIE_se^2)
  TE_p = 2*pnorm(-abs(log_TE/log_TE_se), lower.tail = T)
  OR_TE = exp(log_TE)
  OR_TE_low = exp(log_TE-1.96*log_TE_se)
  OR_TE_high = exp(log_TE+1.96*log_TE_se)
  OR_TE = exp(log_TE)
  proportion = log_NIE/log_TE
  
  result = data.frame(OR_NDE,OR_NDE_low,OR_NDE_high,NDE_p,
                      OR_NIE,OR_NIE_low,OR_NIE_high,NIE_p,
                      OR_TE,OR_TE_low,OR_TE_high,TE_p,proportion)
  
  return(result)
  
  
}



# fit_model = mediate(med_model, out_model, treat='SCORESUM', mediator= "med_var", 
#                     #outcome = c("censor_days_cancer_ignore", "case_control_cancer_ignore"),
#                     boot=T, boot.ci.type = "bca")
#result_list = list(med_model, out_model, fit_model,total_model)
#save(result_list, file = paste0("./result/mediation_result_",i1,".rdata"))
save(result, file = paste0("./result/mediation_result_delta_",i1,".rdata"))
data_new = readRDS("./data/mediation_prscomp_chip.rds")



# 
# 
# #fit the total_effect model
# if(med_var_name=="Former"){
#   total_model = glm(case_control_cancer_ignore~ SCORESUM_sd  + age + age2 + YRI_scale + ASN_scale + Current + sex_new + white_blood_cell_count, 
#                     data = data_clean,
#                     family = "binomial")
#   
# }else if(med_var_name=="Current"){
#   total_model = glm(case_control_cancer_ignore~SCORESUM_sd + age + age2 + YRI_scale + ASN_scale + Former + sex_new + white_blood_cell_count, 
#                     data = data_clean,
#                     family = "binomial")
# }else if(med_var_name=="YRI_scale"){
#   total_model = glm(case_control_cancer_ignore~SCORESUM_sd  + age + age2 + ASN_scale + Former + Current + sex_new + white_blood_cell_count, 
#                     data = data_clean,
#                     family = "binomial")
# }else if(med_var_name=="ASN_scale"){
#   total_model = glm(case_control_cancer_ignore~SCORESUM_sd  + age + age2 + YRI_scale + Former + Current + sex_new + white_blood_cell_count, 
#                     data = data_clean,
#                     family = "binomial")
# }else if(med_var_name=="white_blood_cell_count"){
#   total_model = glm(case_control_cancer_ignore~SCORESUM_sd  + age + age2 + YRI_scale + ASN_scale + Former + Current + sex_new, 
#                     data = data_clean,
#                     family = "binomial")
# }else{
#   total_model = glm(case_control_cancer_ignore~SCORESUM_sd  + age + age2 + YRI_scale + ASN_scale + Former + Current + sex_new + white_blood_cell_count, 
#                     data = data_clean,
#                     family = "binomial")
#   
# }