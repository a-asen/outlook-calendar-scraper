// Paste this in your browser and run getCalData() followed by download(dData)

// Parameters
var how_many_weeks = 85
var dData = []

// Get forward button 
var getForwardButton = document.querySelectorAll( 'button[class*="ms-Button ms-Button--icon"]' )[2]
    // as per now, it is the second in the retrieved list

// Function to run through the calendar with a delay.
    // https://stackoverflow.com/a/63736091
const timer = ms => new Promise(res => setTimeout(res,ms))

async function getCalData(){
    for(let i=0; i < how_many_weeks; i++){
        console.log(i)

        /// Get data 
        var getCalendarEntries = document.querySelectorAll("div.LqGse")
            // Not sure if the selector ("LqGse content") is the same for every computer, but it is consistent for me.
    
        for (let i=0; i < getCalendarEntries.length; i++) {
            dData.push( getCalendarEntries[i].getAttribute("aria-label") + "¤" ) 
                // Each information piece is split by ,
                // Split by ; to separate each entry.
        }
    
        // Click the next page
        getForwardButton.click()
        
        // Wait a bit for the page to load
        await timer(500)
    }
}


// Function to download the data as a CSV file
// Source: https://www.geeksforgeeks.org/how-to-create-and-download-csv-file-in-javascript/
const download = (data) => {
    // Create a Blob with the CSV data and type
    const blob = new Blob([data], { type: 'text/csv' });
    
    // Create a URL for the Blob
    const url = URL.createObjectURL(blob);
    
    // Create an anchor tag for downloading
    const a = document.createElement('a');
    
    // Set the URL and download attribute of the anchor tag
    a.href = url;
    a.download = 'outlook-calendar-scraper.txt';
    
    // Trigger the download by clicking the anchor tag
    a.click();
}
