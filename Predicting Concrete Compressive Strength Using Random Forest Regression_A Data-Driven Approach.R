#############################
# Load Neccessary Libraries #
#############################
library(tidyverse)    # For data manipulation and plotting
library(caret)        # For machine learning workflow and hyperparameter tuning
library(ranger)       # Fast implementation of random forest
library(ggplot2)      # For plotting


###############
# Data Import #
###############
# Read the dataset (update file path as needed)
data <- read.csv("C:/compresive_strength_concrete.csv", stringsAsFactors = FALSE)


#######################
# Inspect the dataset #
#######################
# View structure and summary of the data
str(data)
summary(data)


##################################
# Rename Columns for Consistency #
##################################
# Rename columns for easier reference
colnames(data) <- c(
  "cement", "blast_furnace_slag", "fly_ash", "water", "superplasticizer",
  "coarse_aggregate", "fine_aggregate", "age", "compressive_strength"
)

############################
# Check for missing values #
############################
# Check for missing values
sum(is.na(data))


######################
# Summary Statistics #
######################
# Summary statistics
summary(data)


########################
# Correlation Analysis #
########################
# Compute correlation matrix
correlation_matrix <- cor(data)
print(correlation_matrix)


#######################################################################
# Data Partitioning: Split the dataset into training and testing sets #
#######################################################################
# Set seed for reproducibility
set.seed(123)

# Create partition indices
trainIndex <- createDataPartition(data$compressive_strength, p = 0.8, list = FALSE)

# Split the data into training and testing sets
dataTrain <- data[trainIndex, ]
dataTest <- data[-trainIndex, ]


##################################################################################################
# Model Training: Train a Random Forest model using the 'ranger' method within the caret package #
##################################################################################################
# Define cross-validation strategy
train_control <- trainControl(method = "cv", number = 10)

# Define hyperparameter grid
rf_grid <- expand.grid(
  mtry = c(2, 3, 4),
  splitrule = "variance",
  min.node.size = c(1, 5, 10)
)

# Train the random forest model
set.seed(123)
rf_model <- train(
  compressive_strength ~ ., 
  data = dataTrain,
  method = "ranger",
  trControl = train_control,
  tuneGrid = rf_grid,
  importance = "impurity"
)

######################################################################
# Model Evaluation: Evaluate the model's performance on the test set #
######################################################################
# Predict on test set
predictions <- predict(rf_model, newdata = dataTest)

# Calculate RMSE
rmse <- sqrt(mean((predictions - dataTest$compressive_strength)^2))
cat("RMSE on test set:", rmse, "\n")

# Plot predicted vs. actual values
ggplot(dataTest, aes(x = compressive_strength, y = predictions)) +
  geom_point(color = "darkgreen", size = 2) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  labs(title = "Predicted vs. Actual Concrete Compressive Strength",
       x = "Actual Compressive Strength",
       y = "Predicted Compressive Strength") +
  theme_minimal()


############################################################################
# Variable Importance: Assess the importance of each variable in the model #
############################################################################
# Variable importance
importance_values <- varImp(rf_model)
plot(importance_values, main = "Variable Importance in Random Forest Model")

