import { LightningElement, wire, track, api } from "lwc";
import getDashboards from "@salesforce/apex/ScheduleDashboardToExtUserController.getDashboards";
import scheduleDashboardsLwc from "@salesforce/apex/ScheduleDashboardToExtUserController.scheduleDashboardsLwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

export default class ScheduleDashboardToExternalUser extends LightningElement {
    @api
    get selectedDashboardId() {
        return this._selectedDashboardId;
    }
    set selectedDashboardId(value) {
        this._selectedDashboardId = value;
    }

    @track _selectedDashboardId = null;
    @track selectedDashboardIds = [];
    wiredDashboardsResult;

    @track selectedAction = "subscription";

    get actionOptions() {
        return [
            { label: "Subscription", value: "subscription" },
            { label: "Unsubscription", value: "unsubscription" }
        ];
    }

    get cardTitle() {
        return this.isSubscription
            ? "Select Dashboard to Schedule"
            : "Delete Scheduled Dashboards";
    }

    get isSubscription() {
        return this.selectedAction === "subscription";
    }

    get isUnsubscription() {
        return this.selectedAction === "unsubscription";
    }

    handleActionChange(event) {
        this.selectedAction = event.target.value;
        if (this.selectedAction === "subscription" && this.wiredDashboardsResult) {
            refreshApex(this.wiredDashboardsResult);
        } else if (this.selectedAction === "unsubscription") {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                const deleteComp = this.template.querySelector(
                    "c-delete-schedule-dash-to-ext-user-cardless"
                );
                if (deleteComp) {
                    deleteComp.refresh();
                }
            }, 0);
        }
    }

    // Track frequency selection
    @track frequency = "Weekly";

    get frequencyOptions() {
        return [
            { label: "Daily", value: "Daily" },
            { label: "Weekly", value: "Weekly" },
            { label: "Monthly", value: "Monthly" }
        ];
    }

    get buttonLabel() {
        return "Schedule Dashboard " + this.frequency;
    }

    // Track loading state
    @track isLoading = false;

    // Store all dashboards
    @track dashboards = [];

    // Store filtered dashboards
    @track filteredDashboards = [];

    // Datatable columns
    columns = [
        {
            label: "Dashboard Name",
            fieldName: "dashboardName",
            type: "text",
            sortable: true
        },
        {
            label: "Folder",
            fieldName: "folderName",
            type: "text",
            sortable: true
        }
    ];

    // Check if the schedule button should be disabled
    get isButtonDisabled() {
        return this.selectedDashboardIds.length === 0 || this.isLoading;
    }

    // Load dashboards from Apex
    @wire(getDashboards)
    wiredDashboards(result) {
        this.wiredDashboardsResult = result;
        const { error, data } = result;
        if (data) {
            this.dashboards = data;
            this.filteredDashboards = [...data];
        } else if (error) {
            console.error("Error loading dashboards", error);
            this.showToast("Error", "Failed to load dashboards.", "error");
        }
    }

    // Search dashboards
    handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();
        if (!searchKey) {
            this.filteredDashboards = [...this.dashboards];
            return;
        }

        this.filteredDashboards = this.dashboards.filter((dashboard) => {
            const dashboardName = dashboard.dashboardName
                ? dashboard.dashboardName.toLowerCase()
                : "";
            const folderName = dashboard.folderName
                ? dashboard.folderName.toLowerCase()
                : "";
            return dashboardName.includes(searchKey) || folderName.includes(searchKey);
        });
    }

    // Handle row selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedDashboardIds = selectedRows.map((row) => row.dashboardId);

        // Set fallback single ID for compatibility
        if (selectedRows.length > 0) {
            this._selectedDashboardId = selectedRows[0].dashboardId;
        } else {
            this._selectedDashboardId = null;
        }
    }

    // Handle frequency change
    handleFrequencyChange(event) {
        this.frequency = event.detail.value;
    }

    // Handle dashboard scheduling
    handleScheduleDashboard() {
        if (this.selectedDashboardIds.length === 0) {
            return;
        }

        this.isLoading = true;
        scheduleDashboardsLwc({
            dashboardIds: this.selectedDashboardIds,
            frequency: this.frequency
        })
        .then(() => {
            this.selectedDashboardIds = [];
            this._selectedDashboardId = null;
            let frequencyMsg = "";
            if (this.frequency === "Daily") {
                frequencyMsg = "daily (at 11:55 PM)";
            } else if (this.frequency === "Weekly") {
                frequencyMsg = "weekly (Sunday at 11:55 PM)";
            } else if (this.frequency === "Monthly") {
                frequencyMsg = "monthly (on the 1st of every month at 11:55 PM)";
            }
            this.showToast(
                "Success",
                `The selected dashboard(s) were successfully scheduled to run ${frequencyMsg} and send emails to the external user.`,
                "success"
            );
            return refreshApex(this.wiredDashboardsResult);
        })
        .catch((error) => {
            console.error("Error scheduling dashboards", error);
            const message = error.body ? error.body.message : "Unknown error";
            this.showToast(
                "Error",
                "Failed to schedule dashboard(s): " + message,
                "error"
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    // Helper to show toasts
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}
