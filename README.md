# Hospital Performance & Efficiency Decision Support System (Romania, 2024)

An interactive analytics system developed to evaluate the performance and efficiency of Romanian public hospitals through **statistical analysis, efficiency modeling, and business intelligence visualization**. The project combines **PCA, Cluster Analysis, DEA BCC, and Power BI** to transform hospital operational data into actionable management insights.

---

## Executive Overview

The analysis started from a national database of **342 public hospitals**. After data validation, missing-value checks, and outlier investigation, the final analytical sample included **121 comparable hospitals**, while **65 hospitals** were evaluated through DEA within a homogeneous cluster.

### Key Results

* **121 public hospitals** included in the final analysis;
* **3 distinct hospital profiles** identified through clustering;
* **65 hospitals** evaluated with a DEA BCC output-oriented model;
* Average bed occupancy rate: **55.2%**;
* Lower-level hospitals: **48%** occupancy rate;
* Strong resource–activity relationship: **r = 0.90**.

---

## What the Data Revealed

The analysis showed that hospitals with more resources generally treat more patients, but resource availability alone does not explain performance differences. Hospitals with similar staffing levels, bed capacity, and expenditure often achieve substantially different activity levels, indicating important differences in operational efficiency.

The most striking result was the low utilization of capacity in lower-level hospitals, where fewer than half of available beds were occupied on average. This points to a significant opportunity for performance improvement without increasing resources.

---

## Analytical Workflow

1. Data cleaning and validation
2. Principal Component Analysis (PCA)
3. Cluster Analysis (k-means)
4. DEA BCC output-oriented efficiency analysis
5. Interactive Power BI dashboard development

### Key Analytical Decisions

* Removed **5 atypical hospitals** after outlier investigation;
* Standardized variables before clustering;
* Selected **k = 3** using Elbow and Silhouette criteria;
* Applied DEA only within a homogeneous cluster to improve benchmark comparability.

---

# Executive Dashboards

## Performance Dashboard

![Performance Dashboard](images/dashboard_performance.png)

This dashboard provides a national view of hospital performance. The top indicators show that bed occupancy remains well below the level usually associated with efficient capacity utilization. When the data are filtered by competence level, lower-level hospitals emerge as the main source of underutilized capacity.

The regional visualization highlights clear territorial differences, with higher performance concentrated around major medical and university centers.

### Key Insight

Performance disparities are not driven only by funding levels, but also by differences in how hospitals organize and use existing resources.

---

## DEA Efficiency Dashboard

![DEA Dashboard](images/dashboard_dea.png)

The DEA dashboard compares hospitals with peers that have similar structural characteristics. Efficient hospitals define the benchmark frontier, while inefficient hospitals are evaluated relative to achievable peer performance rather than to the national average.

The visualization highlights:

* hospitals operating close to best practice,
* hospitals with the largest improvement gaps,
* potential output gains achievable with current resources.

### Key Insight

Efficiency analysis becomes a practical decision-support tool for prioritizing operational improvement efforts.

---

## Why the Dashboard Matters

The system allows decision-makers to move from static reports to interactive analysis by hospital, county, or competence level. Managers can immediately identify where capacity is underused, which hospitals perform efficiently relative to comparable peers, and where improvement actions are likely to have the greatest impact.

---

## What I Learned

The most important lesson was that **model sophistication cannot compensate for poor comparability**. I initially applied DEA to all hospitals and obtained misleading benchmarks because hospitals with very different structures were compared directly. Introducing clustering before DEA substantially improved the interpretability and credibility of the results.

This project strengthened my skills in:

* statistical analysis,
* efficiency evaluation,
* data validation,
* business intelligence visualization,
* and communicating complex analytical results to non-technical audiences.

---

## Tools

**R · Power BI · PCA · k-means Clustering · DEA BCC · Statistical Analysis · Data Visualization**

---

**Bachelor thesis project developed at the Bucharest University of Economic Studies (ASE Bucharest).**
