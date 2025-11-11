Holistic Microgrid Planning for E-Mobility InfrastructureThis repository contains the complete MATLAB implementation for the methodology described in the paper: "Holistic approach for microgrid planning for e-mobility infrastructure under consideration of long-term uncertainty" (Sustainable Energy, Grids and Networks, 2023).This project was a significant undertaking, evolving from a complex set of interconnected scripts into the systematic, multi-stage optimization model you see here. It's designed to find the most cost-effective and robust microgrid design (PV, wind, batteries, hydrogen, etc.) to support a growing electric vehicle fleet while accounting for the deep uncertainty in how fast that EV adoption will happen.The core of this project is a two-stage holistic planning model:E-Mobility Simulation: A Monte-Carlo-based model that simulates 1-minute driving and charging behavior for a fleet of EVs. This generates realistic hourly load profiles for 10 years under three different adoption scenarios (Negative, Trend, Positive).Deterministic Optimization (Stage 1): A 10-year SOCP-based optimization that finds the absolute lowest cost microgrid design for a known EV scenario.Stochastic Optimization (Stage 2 - IGDM): This is the core of the paper. It uses the Information Gap Decision Method (IGDM) to find the most robust investment plan. It answers the question: "How much extra should I invest to ensure my microgrid can handle a future with way more EVs than I'm expecting?"A Quick Note on This Code's JourneyYou're not just looking at a final script; you're looking at the result of an intensive debugging and refactoring effort. The original code was a complex, single-file script with several critical flaws that prevented it from running, let alone producing correct results.This version is now systematically organized and fixes all known logical and financial flaws:Fixed all variable scope errors (NOD, LIN, ANZ, H2, etc.) by refactoring the code into a main orchestrator script and pure helper functions.Corrected the Financial Model: Implemented the paper's dynamic $CO_2$ price (from Fig 2.7) and fixed the O&M cost calculations (Flaw 1).Corrected the Technical Constraints:Fixed the Battery (BESS) efficiency to 95% (Flaw 3).Added the 70% efficiency constraint to the Electrolyzer (Flaw 2).Fixed the H2.decay copy-paste bug.Implemented the Correct Power Flow: Re-implemented the SOCP (Second-Order Cone Programming) constraints (Flaw 4) that were missing, including full reactive power dispatch for all DERs (Flaw 1 - part 2).Cleaned the Code Logic: Removed the confusing "Grid-as-CHP" logic and replaced it with a clean Grid.P_import variable (Flaw 3).Stabilized the EV Simulation: Refactored the entire E-Mobility module to remove all global variables, fixing the "0 load" bug and making the simulation reliable.This repository is the version of the code that actually works and aligns with the paper's methodology.DependenciesMATLAB (tested on R2021b and later)YALMIP (Toolbox) - Essential for modeling.Gurobi (Solver) - The solver used in this model. (You can swap it for another SOCP-capable solver, but you'll need to change the ops settings).How to Use This CodeFollow these steps in order.Step 1: Set Up the File StructureClone this repository and ensure your folder structure looks exactly like this. All helper functions must be in the /functions/ folder for the main scripts to find them./Holistic_Microgrid_Optimization/
│
│   (These are the scripts you will run)
├── MAIN_create_all_scenarios.m     (<- RUN THIS FIRST)
├── MAIN_Run_Holistic_Optimization.m  (<- RUN THIS SECOND)
│
│   (These are the plotting scripts)
├── plot_ev_validation_figures.m
├── plot_deterministic_results.m
├── plot_advanced_analysis_figures.m
│
│   (This folder will be created by Step 2)
├── E_Mobility_Data/
│
│   (This folder will be created by Step 3)
└── Results/
│
│   (All .m and data files go in here)
└── functions/
    ├── 1_Files/
    │   ├── 1_NetData/
    │   │   └── MG.xlsx
    │   ├── 3_Matlab/
    │   ├── EV/
    │   │   └── EVS.mat
    │   ├── load_profiles/
    │   │   └── LoadProfiles.mat
    │   │   └── MG_prof.xlsx
    │   ├── Heating/
    │   │   └── MG_heatgrid.xlsx
    │   │   └── space_heating.mat
    │   │   └── water_heating.mat
    │   └── wind/
    │       └── wind.mat
    │
    ├── Allp.m
    ├── LoadDat.m
    ├── InterpDat.m
    ├── InterpDat_heat.m
    ├── AllocProfs.m
    ├── EditBranch.m
    ├── Admitt.m
    ├── CalcLtg.m  (You must provide this)
    ├── CalcTra.m  (You must provide this)
    ├── TN.m       (You must provide this)
    ├── wtarrifs.m
    ├── setup_optimization_parameters.m
    ├── Deterministic_main1.m
    ├── Copy_of_IGDM.m
    ├── run_ev_simulation.m
    ├── GetEVPublicLoad.m
    ├── PDF_TravelBehaviour2.m
    ├── RandByPDF.m
    ├── Mileage.m
    ├── GetPreviousSOC.m
    ├── Int32_Find.m
    └── ... (and all other .m helper files)
Step 2: Generate the EV Load ScenariosRun the E-Mobility simulation. This will read your EVS.mat and travel_behaviour.xlsx data and generate the three required EV_..._h1.mat load files.Matlab>> MAIN_create_all_scenarios
This will create EV_negative_h1.mat, EV_trend_h1.mat, and EV_positive_h1.mat in the /E_Mobility_Data/ folder.(Optional): Run plot_ev_validation_figures.m to see high-quality plots confirming the EV simulation is working correctly.Step 3: Run the Full 10-Year OptimizationThis is the main event. This script will run the full 10-year analysis for all 3 scenarios and then run the 9-point IGDM analysis for the "Trend" scenario.This will take a long time to run.Matlab>> MAIN_Run_Holistic_Optimization
This script will:Set DEBUG_MODE = false (to run the full 8760-hour, 10-year simulation).Run Stage 1 (Deterministic) for all 3 scenarios.Save the results in the /Results/ folder (e.g., deterministic_results_trend.mat).Run Stage 2 (IGDM) for the "Trend" scenario across 9 different budget points.Save the final IGDM results in /Results/stochastic_results_igdm.mat.(To test the code quickly, you can set DEBUG_MODE = true inside the script. This will run a 24-hour simulation for 1 year and skip Stage 2.)Step 4: Visualize the Final ResultsOnce the main simulation is finished, run the plotting scripts from your root folder to generate all the figures from the paper and the new strategic analysis plots.Matlab>> plot_deterministic_results
>> plot_stochastic_results
>> plot_advanced_analysis_figures
CitationIf this code and methodology are useful for your research, please cite the original paper:M. Tayyab, I. Hauer, S. Helm. "Holistic approach for microgrid planning for e-mobility infrastructure under consideration of long-term uncertainty." Sustainable Energy, Grids and Networks, Vol. 34, 2023, 101073.https://doi.org/10.1016/j.segan.2023.101073LicenseThis project is licensed under the MIT License. See the LICENSE file for details.

# optimizatiion-with-long-term-uncertainty

Cite:
Muhammad Tayyab, Ines Hauer, Sebastian Helm,
Holistic approach for microgrid planning for e-mobility infrastructure under consideration of long-term uncertainty,
Sustainable Energy, Grids and Networks,
Volume 34,
2023,
101073,
ISSN 2352-4677,
https://doi.org/10.1016/j.segan.2023.101073.
(https://www.sciencedirect.com/science/article/pii/S2352467723000814)



Abstract: Integrating renewable energy sources in sectors such as electricity, heat, and transportation has to be planned economically, technologically, and emission-efficient to address global environmental issues. Microgrids appear to be the solution for large-scale renewable energy integration in these sectors. The microgrid components must be optimally planned and operated to prevent high costs, technical issues, and emissions. Existing approaches for optimal microgrid planning and operation in the literature do not include a solution for e-mobility infrastructure development. Consequently, the authors provide a compact new methodology that considers the placement and the stochastic evolution of e-mobility infrastructure. In this new methodology, a retropolation approach to forecast the rise in the number of electric vehicles, a monte-carlo simulation for electric vehicle (EV) charging behaviors, a method for the definition of electric vehicle charging station (EVCS) numbers based on occupancy time, and public EVCS placement based on monte-carlo simulation have been developed. A deterministic optimization strategy for the planning and operation of microgrids is created using the abovementioned methodologies, which additionally consider technical power system issues. As the future development of e-mobility infrastructure has high associated uncertainties, a new stochastic method referred to as the information gap decision method (IGDM) is proposed. This method provides a risk-averse strategy for microgrid planning and operation by including long-term uncertainty related to e-mobility. Finally, the deterministic and stochastic methodologies are combined in a novel holistic approach for microgrid design and operation in terms of cost, emission, and robustness. The proposed method has been tested in a new settlement area in Magdeburg, Germany, under three different EV development scenarios (negative, trend, and positive). EVs are expected to reach 31 percent of the total number of cars in the investigated settlement area. Due to this, three public electric vehicle charging stations will be required in the 2031 trend scenario. Thus, the investigated settlement area requires a total cost of 127,029 €. In association with possible uncertainties, the cost of the microgrid must be raised by 80 percent to gain complete robustness against long-term risks in the development of EVCS.
Keywords: Electric vehicle charging station; Electric vehicle; Monte-Carlo simulation; Information gap decision method; E-mobility infrastructure; Holistic approach; Optimizations; Sector coupling
