# Flight-Data-Visualisation

This is a data visualization project, built from an R script. It makes use of Shiny library to make a WebApp. The projects start off with web-scraping the FlightAware website to search for flights of AirFrance and collect them into one dataframe. Then we carry out the data cleaning on this by removing columns that are not of use to our analysis. After we have cleaned the data, we move forward to creating columns with specific information like arrival time, departure time, destination, origination, latitude, airports etc. 
After the data has been prepared, we move forward to the data visualization part. We use Plotly and Mapbox, to visualize a world map containing the flight paths and mapping them. We mark the airports, flights, and paths with different colors for incoming and outgoing flights. This completes our visualization part. 
Now, we complete making the WebApp from this visualization script. We use HTML to write the user-interface of the WebApp and then create a server function that when called will import dependencies and run our R-script. Thus, it will render all the reactive and dormant objects of our script.

![plotted graph](http://url/to/img.png)
