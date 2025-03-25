#############################
# Install & Load Libraries  #
#############################
# Install gridExtra if not installed
if (!require("gridExtra")) {
  install.packages("gridExtra")
}
library(tidyverse)    # Data manipulation and plotting
library(caret)        # Machine learning workflow and hyperparameter tuning
library(ranger)       # Fast implementation of random forest
library(ggplot2)      # Plotting
library(reshape2)     # For melting data for heatmaps
library(gridExtra)    # To arrange multiple plots

###############
# Data Import #
###############
# Read the dataset (update file path as needed)
data <- read.csv("C:/compresive_strength_concrete.csv", stringsAsFactors = FALSE)

#######################
# Inspect the dataset #
#######################
str(data)
summary(data)

##################################
# Rename Columns for Consistency #
##################################
colnames(data) <- c(
  "cement", "blast_furnace_slag", "fly_ash", "water", "superplasticizer",
  "coarse_aggregate", "fine_aggregate", "age", "compressive_strength"
)

############################
# Check for missing values #
############################
cat("Total missing values:", sum(is.na(data)), "\n")

######################
# Summary Statistics #
######################
summary(data)

########################
# Correlation Analysis #
########################
correlation_matrix <- cor(data)
print(correlation_matrix)

# Heatmap of correlation matrix
melted_cor <- melt(correlation_matrix)
p_heat <- ggplot(melted_cor, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, limit = c(-1,1)) +
  labs(title = "Correlation Heatmap", x = "", y = "") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
print(p_heat)

##############################################
# Data Partitioning: Split into Training and Testing Sets
##############################################
set.seed(123)
trainIndex <- createDataPartition(data$compressive_strength, p = 0.8, list = FALSE)
dataTrain <- data[trainIndex, ]
dataTest <- data[-trainIndex, ]

##############################################
# Model Training: Random Forest using ranger in caret
##############################################
train_control <- trainControl(method = "cv", number = 10)
rf_grid <- expand.grid(
  mtry = c(2, 3, 4),
  splitrule = "variance",
  min.node.size = c(1, 5, 10)
)
set.seed(123)
rf_model <- train(
  compressive_strength ~ ., 
  data = dataTrain,
  method = "ranger",
  trControl = train_control,
  tuneGrid = rf_grid,
  importance = "impurity"
)

##############################################
# Model Evaluation: Performance on Test Set
##############################################
predictions <- predict(rf_model, newdata = dataTest)
rmse <- sqrt(mean((predictions - dataTest$compressive_strength)^2))
cat("RMSE on test set:", rmse, "\n")

p_scatter <- ggplot(dataTest, aes(x = compressive_strength, y = predictions)) +
  geom_point(color = "darkgreen", size = 2) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  labs(title = "Predicted vs. Actual Compressive Strength",
       x = "Actual", y = "Predicted") +
  theme_minimal()
print(p_scatter)

##############################################
# Additional Visualizations
##############################################

# 1. Density Plot for compressive strength
p_density <- ggplot(data, aes(x = compressive_strength)) +
  geom_density(fill = "skyblue", alpha = 0.5) +
  labs(title = "Distribution of Compressive Strength", x = "Compressive Strength", y = "Density") +
  theme_minimal()

# 2. Bar Graph: Frequency count of binned compressive strength
data <- data %>%
  mutate(strength_bin = cut(compressive_strength, breaks = 10))
p_bar <- ggplot(data, aes(x = strength_bin)) +
  geom_bar(fill = "orange", color = "black", alpha = 0.7) +
  labs(title = "Frequency Distribution of Compressive Strength", x = "Strength Bins", y = "Count") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# 3. Box Plot: Distribution of compressive strength
p_box <- ggplot(data, aes(y = compressive_strength)) +
  geom_boxplot(fill = "lightgreen", color = "darkgreen") +
  labs(title = "Box Plot of Compressive Strength", y = "Compressive Strength") +
  theme_minimal()

# 4. Stunting Chart (if stunting variable exists; if not, display a placeholder)
if("stunting" %in% names(data)) {
  p_stunt <- ggplot(data, aes(x = factor(stunting), y = compressive_strength)) +
    geom_boxplot(fill = "violet", color = "purple") +
    labs(title = "Compressive Strength by Stunting Category", x = "Stunting Category", y = "Compressive Strength") +
    theme_minimal()
} else {
  p_stunt <- ggplot(data, aes(x = "", y = compressive_strength)) +
    geom_boxplot(fill = "violet", color = "purple") +
    labs(title = "Compressive Strength Distribution (No Stunting Data)") +
    theme_minimal()
}

# Arrange additional plots in a grid
grid.arrange(p_scatter, p_density, p_bar, p_box, p_stunt, ncol = 2)

##############################################
# Variable Importance Plot
##############################################
importance_values <- varImp(rf_model)
plot(importance_values, main = "Variable Importance in Random Forest Model")
