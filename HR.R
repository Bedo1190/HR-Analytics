knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE, dpi = 300)
# Install packages
required_packages <- c("tidyverse", "rpart", "rpart.plot", "caret", "knitr", 
                       "randomForest", "gridExtra", "scales", "dbscan", "reshape2")

for(p in required_packages) {
  if(!require(p, character.only = TRUE)) install.packages(p, dependencies = TRUE)
}

library(tidyverse)
library(rpart)
library(rpart.plot)
library(caret)
library(knitr)
library(randomForest)
library(gridExtra)
library(scales)
library(dbscan)   
library(reshape2)
# Load Data
if (file.exists("HRDataset_v14.csv")) {
  df <- read.csv("HRDataset_v14.csv", stringsAsFactors = FALSE)
} else {
  stop("HRDataset_v14.csv not found.")
}


# 1. Date Conversion
df$DateofHire <- as.Date(df$DateofHire, format="%m/%d/%Y")
df$DateofTermination <- as.Date(df$DateofTermination, format="%m/%d/%Y")
df$DOB <- as.Date(df$DOB, format="%m/%d/%Y")

# 2. Tenure Calculation (Critical Predictor)
current_date <- max(df$DateofHire, na.rm = TRUE) + 30 
df$TenureDays <- ifelse(is.na(df$DateofTermination), 
                        as.numeric(current_date - df$DateofHire),
                        as.numeric(df$DateofTermination - df$DateofHire))

# 3. Age Calculation
df$Age <- as.numeric(difftime(current_date, df$DOB, units = "weeks")) / 52.25

# 4. Target & Factor Cleaning
df$Termd <- as.factor(df$Termd)
df <- df %>% mutate_if(is.character, as.factor)

# Table of Cleaned Data
clean_log <- data.frame(
  Step = c("Date Parsing", "Feature Eng.", "Feature Eng.", "Formatting"),
  Action = c("Converted strings to Date objects", "Calculated 'TenureDays'", "Calculated 'Age' from DOB", "Converted strings to Factors"),
  Benefit = c("Allows time-series analysis", "Strongest predictor of turnover", "Demographic insights", "Required for ML models")
)
kable(clean_log, caption = "Data Preparation Log")
# Select numeric columns for LOF
lof_data <- df %>% select(Salary, Absences, TenureDays, Age, EmpSatisfaction) %>% na.omit()
lof_data_scaled <- scale(lof_data) # Scale data for distance calculation

# Calculate LOF (k=5 neighbors)
lof_scores <- lof(lof_data_scaled, minPts = 5)
df_lof <- df[rownames(lof_data), ]
df_lof$LOF_Score <- lof_scores

# Plot LOF Density
p1 <- ggplot(df_lof, aes(x = LOF_Score)) +
  geom_density(fill = "orange", alpha = 0.6) +
  geom_vline(xintercept = 1.5, linetype="dashed", color="red") +
  labs(title = "LOF Score Density", subtitle = "Scores > 1.5 are outliers") +
  theme_minimal()

# Plot Top Outliers (Salary vs Tenure)
p2 <- ggplot(df_lof, aes(x = TenureDays, y = Salary, color = LOF_Score > 1.5)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = c("gray", "red"), labels = c("Normal", "Outlier")) +
  labs(title = "Outliers in Context", subtitle = "Salary vs Tenure") +
  theme_minimal() + theme(legend.position="bottom")

grid.arrange(p1, p2, ncol=2)
#Creating a focused table to show exactly why they were flagged
top_outliers <- df_lof %>% 
  arrange(desc(LOF_Score)) %>% 
  select(Employee_Name, Position, Salary, Absences, LOF_Score) %>% 
  head(5)

kable(top_outliers, caption = "Top 5 Anomalous Employees (LOF)")
# Select numeric cols
num_cols <- df %>% select(Salary, EmpSatisfaction, SpecialProjectsCount, Absences, DaysLateLast30, Age)
cormat <- round(cor(num_cols, use = "complete.obs"), 2)
melted_cormat <- melt(cormat)

ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + 
  geom_tile() +
  geom_text(aes(label = value), color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1)) +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Feature Correlation Heatmap", x="", y="")
ggplot(df, aes(x = PerformanceScore, fill = Termd)) +
  geom_bar(position = "fill") +
  scale_fill_manual(values = c("gray", "#d9534f"), labels=c("Active", "Terminated")) +
  coord_flip() +
  labs(title = "Turnover Rate by Performance Score", y = "Proportion") +
  theme_minimal()
# Calculate average satisfaction by Manager
manager_sat <- df %>%
  group_by(ManagerName) %>%
  summarise(Avg_Sat = mean(EmpSatisfaction, na.rm = TRUE),
            Count = n()) %>%
  filter(Count > 3) %>% # Filter out managers with very few staff to avoid skew
  arrange(Avg_Sat)

# Plot
ggplot(manager_sat, aes(x = reorder(ManagerName, Avg_Sat), y = Avg_Sat)) +
  geom_point(size = 4, color = "steelblue") +
  geom_segment(aes(x=ManagerName, xend=ManagerName, y=0, yend=Avg_Sat), color="skyblue") +
  coord_flip() +
  labs(title = "Average Employee Satisfaction by Manager",
       subtitle = "Which managers drive the highest team morale?",
       x = "", y = "Average Satisfaction (1-5)") +
  theme_minimal()

# Filter to top 6 sources to keep the chart readable
top_sources <- names(sort(table(df$RecruitmentSource), decreasing = TRUE))[1:6]
df_subset <- df %>% filter(RecruitmentSource %in% top_sources)

ggplot(df_subset, aes(x = RecruitmentSource, fill = Termd)) +
  geom_bar(position = "fill") +
  scale_fill_manual(values = c("gray", "#d9534f"), labels=c("Active", "Terminated")) +
  labs(title = "Turnover Risk by Recruitment Source",
       subtitle = "Proportion of terminations for top hiring sources",
       x = "Source", y = "Proportion Terminated") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")
ggplot(df, aes(x = Department, y = Salary, fill = Department)) +
  geom_boxplot(alpha = 0.7, show.legend = FALSE) +
  labs(title = "Salary Ranges by Department",
       subtitle = "Visualizing pay spread and departmental outliers",
       x = "", y = "Salary ($)") +
  scale_y_continuous(labels = dollar_format()) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
# Data Split
set.seed(123)
model_data <- df %>% 
  select(Termd, Salary, EmpSatisfaction, SpecialProjectsCount, 
         Absences, TenureDays, Age, DeptID) %>% drop_na()

trainIndex <- createDataPartition(model_data$Termd, p = .7, list = FALSE)
trainData <- model_data[trainIndex, ]
testData  <- model_data[-trainIndex, ]

# 1. Single Decision Tree
tree_model <- rpart(Termd ~ ., data = trainData, method = "class")

# 2. Random Forest
rf_model <- randomForest(Termd ~ ., data = trainData, ntree=100)
rpart.plot(tree_model, type = 4, extra = 104, 
           box.palette = "RdBu", shadow.col = "gray", 
           main = "Termination Decision Rules")
# Predict
rf_pred <- predict(rf_model, testData)
cm <- confusionMatrix(rf_pred, testData$Termd)
acc <- round(cm$overall['Accuracy']*100, 2)

# Visualization of Results
cm_d <- as.data.frame(cm$table)
cm_d$Prediction <- factor(cm_d$Prediction, levels=rev(levels(cm_d$Prediction)))

# Plot 1: Confusion Matrix
p1 <- ggplot(cm_d, aes(Reference, Prediction, fill= Freq)) +
  geom_tile() + geom_text(aes(label=Freq), size=8, color="white") +
  scale_fill_gradient(low="gray", high="#2c3e50") +
  labs(title = paste("Accuracy:", acc, "%"),
       subtitle = "Confusion Matrix",
       x = "Actual Status", y = "Predicted Status") +
  theme_minimal() + theme(legend.position="none")

# Plot 2: Variable Importance
# We extract the 'MeanDecreaseGini' which is calculated by default
var_imp_data <- importance(rf_model)
var_imp <- data.frame(Variable = rownames(var_imp_data), 
                      Importance = var_imp_data[, "MeanDecreaseGini"])

p2 <- ggplot(var_imp, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_col(fill = "darkred") +
  coord_flip() +
  labs(title = "Key Drivers of Turnover",
       subtitle = "Variable Importance (Gini)",
       x = "", y = "Importance Score") +
  theme_minimal()

grid.arrange(p1, p2, ncol=2)

