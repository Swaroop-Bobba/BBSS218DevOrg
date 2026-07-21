# SFDX Project Workspace Analysis Report

## Executive Summary
This workspace is a **Salesforce DX (SFDX) Project** (`bbss218`) configured with source API v65.0. It contains core CRM operational logic (Accounts, Leads, Opportunities, Employees) and an embedded sub-project module **`PDFRenderercodes`** (API v58.0) designed specifically for PDF rendering, sales dashboard report generation, and automated multi-frequency email distribution to internal and external stakeholders.

---

## 1. Project Directory Structure

```
bbss218 (Workspace Root)
├── sfdx-project.json (Source API v65.0)
├── force-app/ (Primary SFDX Package Directory)
│   └── main/default/
│       ├── classes/          (Core Apex Handlers, Controllers & Queueables)
│       ├── triggers/         (Account & Employee Triggers)
│       ├── lwc/              (Account Creator & Workshop Finder LWCs)
│       ├── flows/            (12 Record-Triggered & Scheduled Flows)
│       ├── objects/          (Employee__c, SOW__c, PracticeGroupHeadEmail__mdt, etc.)
│       └── pages/            (Visualforce Pages)
│
├── PDFRenderercodes/ (Sub-project / Module for PDF Generation & Dashboard Automation)
│   ├── sfdx-project.json (Source API v58.0, Name: sales-dashboard)
│   └── force-app/main/default/
│       ├── classes/          (Dashboard Scheduling Controllers & Email Schedulers)
│       ├── pages/            (ssDashBoardPage Visualforce PDF Renderer)
│       └── lwc/              (scheduleDashboardToExternalUser UI Component)
│
└── manifest/                 (Metadata package manifests, e.g., allmetadata.xml)
```

---

## 2. `PDFRenderercodes` Module Analysis

The `PDFRenderercodes` module handles PDF rendering and dashboard email automation.

### Key Components

#### **A. Visualforce PDF Generator**
* **Page**: `ssDashBoardPage.page` (`renderAs="PDF"`)
* **Function**: Generates a PDF document for **Super Surfaces - Sales Dashboard**.
* **Features**: Embeds dynamic Salesforce `ChartServer` engine images for various sales KPIs:
  * *Deals Won*: This Month, Last Month, This Quarter
  * *Pipeline Analysis*: This Month, Next Month, Next 90 Days
  * *Regional Breakdown*: Closed SFT, Closed Amount, Revenue Pipeline
  * *KAM & Architect Revenue Performance*

#### **B. Apex Email & PDF Schedulers**
1. **`sendDashboard.cls`**
   * Implements `Schedulable` interface.
   * Uses `@future(callout=true)` to render `ssDashBoardPage.page` into a PDF Blob via `ref.getContent()`.
   * Attaches the PDF Blob (`Super Surfaces - Sales Dashboard - <Timestamp>.pdf`) and sends it to email addresses specified in `System.Label.Report_Email_Addresses`.

2. **`ScheduleDashboardToExtUserController.cls`**
   * Controller powering the LWC dashboard scheduling UI and Flow invocable methods.
   * `getDashboards()`: Queries active Salesforce dashboards filtered by `System.Label.ScheduleDashboardAllowedFolders` while excluding already scheduled jobs.
   * `scheduleDashboard()` & `scheduleDashboardsLwc()`: Systematically constructs cron expressions (`Daily`, `Weekly`, or `Monthly`) and schedules Apex jobs (`ScheduleDashboardToExtUserSchedular`).

3. **`ScheduleDashboardToExtUserSchedular.cls`**
   * Implements `Schedulable` with an asynchronous callout `@future` method `runAndEmailDashboardInternal`.
   * Sends direct dashboard links to configured external email recipients (`System.Label.ScheduleDashboardToExternalUserEmail`).

#### **C. Lightning Web Component (LWC)**
* **`scheduleDashboardToExternalUser`**
  * Admin UI component allowing users to search, select, and subscribe/unsubscribe dashboards for automated email scheduling with configurable frequencies (`Daily`, `Weekly`, `Monthly`).

---

## 3. Main `force-app` Directory Analysis

The primary application directory contains core business logic, record handling, automation flows, and UI modules.

### **Apex Code & Triggers**
* **`AccountHandler.cls`**: Handler logic setting default `Industry` picklist value to `'Technology'` on Account creation.
* **`AccountTrigger.trigger`**: Trigger entry point for Account events (delegated to Flow).
* **`EmployeeSendEmail.cls`** & **`EmployeeTrigger.trigger`**: Automatically sends welcome email notifications asynchronously (`@future`) when new `Employee__c` records are inserted.
* **`UpdateContactLastCheckedQueueable.cls`**: Queueable Apex job updating `Last_Checked__c` date field on Contact records.
* **`WorkshopFinderConfigController.cls`**: Apex controller supporting workshop finder analytics/config.

### **Lightning Web Components (LWC)**
* **`accountCreator`**: Interactive form utilizing `lightning-record-edit-form` to input Account details (Name, Phone, Industry, Type) with built-in toast feedback.
* **`workshopFinderContainer`**: Integration component that dynamically loads tracking scripts (Google Tag / Adobe Tag) and listens to window postMessage events (`registration-complete-event`).

### **Salesforce Flow Automations**
The org includes **12 active flows** handling business processes across key objects:
* **Account**: `Account_After`, `Account_Before_Set_Industry_Technology`
* **Lead**: `Lead_Before`, `Lead_Before2`, `Lead_After`, `Lead_After_for_Task_Count`, `Lead_Schedule`, `Lead_Sheduled_flow_Squence_Follow_up_Mail`
* **Opportunity**: `Opportunity_Before`, `Opportunity_After`
* **Contact & Email**: `Contact_Before_Set_LeadSource_Inbound`, `Email_Sq`

### **Custom Objects & Metadata**
* `Employee__c`: Custom object tracking employee records.
* `SOW__c`: Custom object for Statement of Work records.
* `PracticeGroupHeadEmail__mdt`: Custom Metadata Type storing group head email addresses.
* Custom Labels: `SolutionRecordtype`, `StaffingRecordtype`.
