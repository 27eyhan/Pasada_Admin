class MapManager {
    private map: google.maps.Map | null = null;
    private defaultPosition = { lat: 14.191723, lng: 120.971812 }; // fallback position

    constructor(apiKey: string) {
        this.initializeMap(apiKey);
    }

    private async initializeMap(apiKey: string): Promise<void> {
        // gawa tayo ng map container
        const mapElement = document.createElement('div');
        mapElement.id = 'map';
        mapElement.style.height = '100vh';
        mapElement.style.width = '100vw';
        document.body.appendChild(mapElement);

        // load Google Maps API
        await this.loadGoogleMaps(apiKey);

        // get user's position
        const position = await this.getUserPosition();

        // initialize map
        this.map = new google.maps.Map(mapElement, {
            center: position || this.defaultPosition,
            zoom: position ? 14 : 8,
            disableDefaultUI: true
        });
    }
}