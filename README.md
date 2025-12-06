# HR Data Analytics: Turnover Prediction & Outlier Detection
**Course:** CMPE 343 - Business Intelligence and Applied Analytics
**[📄 Click here to read the full PDF Report](Report.pdf)**

## 1. Project Overview
This project analyzes a synthetic HR dataset of 311 employees to identify key drivers of turnover and detect data anomalies. The goal was to build predictive models to forecast termination risks and use unsupervised learning to find behavioral and structural outliers.

* **Dataset:** HR Dataset v14 (311 rows, full employee lifecycle).
* **Target:** `Termd` (0 = Active, 1 = Terminated).
* **Tech Stack:** R, Random Forest, Rpart (Decision Tree), DBScan (LOF), GGplot2.

---

## 2. Outlier Detection (LOF)
I utilized the **Local Outlier Factor (LOF)** algorithm to identify multidimensional outliers based on Salary, Absences, and Tenure. Unlike simple thresholds, LOF finds local anomalies relative to their neighbors.

**Key Findings:**
* **Behavioral Outliers:** Identified employees like *Jenna Dietrich* (Score: 2.17) who had standard salaries but abnormally high absences (17 days) given their role.
* **Structural Outliers:** Identified *Janet King* (CEO) as a mathematical outlier due to her salary ($250k), which is expected but distant from the population distribution.

<img width="2184" height="1350" alt="LOF" src="https://github.com/user-attachments/assets/ed1b1e23-959f-414f-992a-8055d6fa4087" />

---

## 3. Visual Analysis & Insights
Using correlation matrices and box plots, I derived several business insights:

* **Turnover by Performance:** High performers ("Exceeds") have very low turnover. The highest risk group is employees who "Fully Meet" expectations but have low satisfaction scores.
* **Manager Effectiveness:** There is significant variance in employee satisfaction depending on the manager. Some managers consistently drive higher team morale than others.
* **Recruitment Sources:** "Google Search" hires showed higher turnover rates compared to "Diversity Job Fairs" and "Employee Referrals."

<img width="2427" height="1500" alt="CORRELATİON" src="https://github.com/user-attachments/assets/31e51053-f0ce-44e4-b65a-a873273e9a25" />

---

## 4. Predictive Modeling
I implemented two supervised learning models to predict employee turnover.

### Model 1: Decision Tree (Interpretability)
The single decision tree revealed simple, actionable rules for HR:
* **Rule 1:** If `Tenure` < 528 days and `SpecialProjectsCount` is low, risk is high.
* **Rule 2:** Employees with low satisfaction scores are significantly more likely to leave if they are not on a "Performance Improvement Plan" (PIP).

<img width="2427" height="1500" alt="DECİSİONTREE" src="https://github.com/user-attachments/assets/e105a236-3307-4f33-bc04-17bb7d86f558" />

### Model 2: Random Forest (Accuracy)
* **Method:** Aggregated 100 decision trees to reduce variance.
* **Result:** The Random Forest outperformed the single tree, achieving an **accuracy of ~80% (79.57%)**.
* **Key Drivers:** Variable importance analysis showed that **TenureDays**, **Salary**, and **Age** were the strongest predictors of turnover.
<img width="1941" height="1200" alt="ACCURACY" src="https://github.com/user-attachments/assets/2ca0202a-a33d-4a09-a4da-3a3e1572a34a" />

---
