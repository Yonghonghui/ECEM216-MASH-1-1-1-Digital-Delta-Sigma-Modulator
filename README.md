# ECEM216-MASH-1-1-1-Digital-Delta-Sigma-Modulator
Designed and synthesized a high-speed MASH-1-1-1 Digital Delta-Sigma Modulator targeting a 500MHz clock frequency using the TSMC 16nm FinFET technology library. The project involved complete RTL design, multi-corner synthesis using Synopsys Design Compiler, and sign-off quality power/timing analysis using PrimeTime PX.


# Hardware Realization of a MASH-1-1-1 $\Delta\Sigma$ Modulator

![Language](https://img.shields.io/badge/Language-Verilog-orange.svg)
![Technology](https://img.shields.io/badge/Technology-TSMC_16nm_FinFET-green.svg)
![Frequency](https://img.shields.io/badge/Frequency-500MHz-red.svg)
![Course](https://img.shields.io/badge/UCLA-ECE216A-blue.svg)

> **Course:** ECE 216A - Design of VLSI Circuits and Systems (UCLA)  
> **Group:** 14  
> **Members:** Yanghonghui Chen, Xuancheng Liu

## 📖 Overview

This repository contains the RTL implementation, synthesis scripts, and performance analysis reports for a **MASH-1-1-1 Digital Delta-Sigma Modulator**. 

The design targets a **500 MHz** clock frequency using **TSMC 16nm FinFET** technology. It features a pipelined architecture with robust noise-shaping logic, verified through a complete ASIC flow including gate-level simulation and sign-off power analysis.

## 📂 Repository Structure

```text
.
├── Group_14/                   # Source Codes & Synthesis Reports
│   ├── M216A_TopModule.v       # Top-level Verilog Design (RTL)
│   ├── M216A_Testbench.v       # Testbench for verification & VCD generation
│   ├── Group_14.tcl            # Synopsys Design Compiler (DC) Script
│   ├── Group_14.Area           # Final Area Report
│   ├── Group_14.Power          # DC Estimated Power Report
│   ├── Group_14.TimingSetup    # Setup Time Timing Report
│   └── Group_14.TimingHold     # Hold Time Timing Report
│
├── Group_14.pdf                # Final Project Report (Summary & Diagram)
├── EE216A_Project.pdf          # Project Description / Assignment Spec
└── README.md                   # Project Documentation
