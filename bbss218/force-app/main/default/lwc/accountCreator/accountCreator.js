import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountCreator extends LightningElement {
    @track showSuccess = false;
    @track createdAccountId;

    handleSuccess(event) {
        this.createdAccountId = event.detail.id;
        this.showSuccess = true;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Account created successfully',
                variant: 'success'
            })
        );
    }

    handleError(event) {
        this.showSuccess = false;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error creating account',
                message: event.detail.message || 'Something went wrong.',
                variant: 'error'
            })
        );
    }
}

