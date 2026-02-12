import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
//import getAdobeTagUrl from '@salesforce/apex/WorkshopFinderConfigController.getAdobeTagUrl';
//import GOOGLE_TAG from '@salesforce/resourceUrl/WorkshopFinderGoogleTag';

export default class WorkshopFinderContainer extends LightningElement {
    adobeLoaded = false;

    async connectedCallback() {
        await this.loadTrackingScripts();
        this.registerMessageListener();
    }

    async loadTrackingScripts() {
        try {
            const adobeUrl = await getAdobeTagUrl();

            if (adobeUrl) {
                await loadScript(this, adobeUrl);
            }

            await loadScript(this, GOOGLE_TAG);

        } catch (error) {
            console.error('Script load error', error);
        }
    }

    registerMessageListener() {
        window.addEventListener(
            'message',
            (event) => {
                if (event?.data?.type === 'registration-complete-event') {
                    window.dataLayer = window.dataLayer || [];
                    window.dataLayer.push({
                        event: 'gtm.workshop-registration',
                        'gtm.data': event.data
                    });
                }
            },
            false
        );
    }
}