# R_france_app

![alt text](https://github.com/remicnrd/R_france_app/blob/master/preview.png)

This project is mainly to show the possibilities of R in addition to his initial scope, that is statistical operations.

I created a fully functionnal and user-friendly web application, that uses web scrapping to get live data of Air France flights.
The flights are plotted on a reactive map with a color distinction according to their provenance/destination. The concerned airports are also plotted and differentiated by size according to frequentation.

## Web scraping part
The live flights data are taken from flightaware.com. Once the airline url obtained, the data is displayed in a table but limited to 20 rows per page.
That's why I needed to parse the table as a Dataframe, find the next page link node (I used <a href="http://selectorgadget.com/">SelectorGadget</a> for Chrome) and start the process again.
The last occurences being when the scrapped Dataframe contains less than the max occurences per page (here 20).

## Data munging
From the scrapped Data, some modifications where needed in order to plot what I intended to do.

First, each flight starting point and arrival needed to be uniquely identified. I took the names and extracted only the IACO codes of the airports (<a href="https://en.wikipedia.org/wiki/International_Civil_Aviation_Organization_airport_code">more info on IACO codes</a>).
Then, each IACO must be paired with its coordinates. I imported those from a mondial list from <a href = "http://ourairports.com/data/">OurAirports</a>.

I then added a new dimension to my concerned airports list with the count of departure from and arrival to them. This is the used dimension for the size of the markers on the map.

Finally, I created a boolean variable indicating if a flight is an incoming or outcoming french flight to take a look at the two flows.


## Dataviz
The map is in fact a <a href="https://www.mapbox.com/">Mapbox</a>, using <a href="https://plot.ly/">Plotly</a>.
The main idea is to superimpose the various information layers, that is the map, the airports markers and the flights segments.
All of that toying with available parameters to obtain a pleasant design.

## Web app
Every R script can be turn into a web app using <a href="https://shiny.rstudio.com/">shiny</a>. 
Now you don't necessarily have to structure your app in several files. However the R code has to be separated in a UI and Server part.

Concerning hosting environment there is a possibility to use shiny provided services, or to dockerize the app and deploy it elsewhere.
I've done both and any solution can be good depending on your needs.
