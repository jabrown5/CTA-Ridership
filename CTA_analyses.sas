/* IMPORT CTA 'L' RIDERSHIP FILE */
/* Source File: CTA_Ridership.csv */
/* Source Path: /folders/myfolders/CTA */

FILENAME REFFILE '/folders/myfolders/CTA/CTA_Ridership.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	/* 	outputting data file to manipulate via SAS */
	OUT=CTAdata; 
	GETNAMES=YES;
RUN;

/* SET UP FORMATS FOR DAY OF WEEK */
PROC FORMAT ;
	value dayfmt 	1 = 'Sunday'
					2 = 'Monday'
					3 = 'Tuesday'
					4 = 'Wednesday'
					5 = 'Thursday'
					6 = 'Friday'
					7 = 'Saturday';
RUN;

/* 1 - Convert MMDDYY10 to day of week using 'weekday' fmt
	1 = Sunday
	2 = Monday
	3 = Tuesday
	4 = Wednesday
	5 = Thursday
	6 = Friday
	7 = Saturday 
	
 	2 - CREATE TWO	DATA SETS:
 	CTAdata2 = all days of week regardless of weekends, holidays
 	CTAweekday = includes only weekdays that are not holidays	
 	CTAevanston = includes Main and Davis St 'L' stations for Wed, 4/2/14 (corresponding Metra ride numbers) */
data 	CTAdata2 
		CTAweekday (where=(daytype="W")) 
		CTAevanstonMetra (where=((station_id=40270 or station_id=40050) and date='02apr14'd))
		CTAevanston (where=((station_id=40270 or station_id=40050) and daytype="W"));
		set CTAdata;
	dayOfWeek=weekday(date);
run;



/*****************************************************/
/* CODE TO ASSESS QUESTION 1 */
/* Which stop has the highest average ridership per day, and what is it? */
proc sort data=CTAdata2 ; by dayOfWeek station_id  ; run;

/* proc summary used to cross stations by day of week */
/* data set output with the mean of all rides by day of week */
Proc summary data=CTAdata2 ;
    class stationname dayOfWeek ;
    var rides dayOfWeek ;
    output out=CTAdata3 mean=;
run;

proc sort data=CTAdata3 ;
	by descending rides;
	where dayOfWeek ne . and stationname ne '';
	format dayOfWeek dayfmt.;
run;

proc print data=CTAdata3 (obs=20);
run;



/*****************************************************/
/* CODE TO ASSES QUESTION 2 */
/* Which stop has the greatest standard deviation in weekday (exclude holidays) ridership per day, and what is it? */
proc sort data=CTAweekday; by dayOfWeek station_id  ;  run;

/* proc summary used to cross stations by day of week */
/* data set output with the mean of all rides by day of week */
Proc summary data=CTAweekday (where=(stationname="Lake/State") );
    class stationname dayOfWeek ;
    var rides dayOfWeek ;
    output out=CTAweekday2 sum= std=std_deviation;
run;

proc sort data=CTAweekday2 ;
	by descending std_deviation;
	where dayOfWeek ne . and stationname ne '';
	format dayOfWeek dayfmt.;
run;

proc print data=CTAweekday2 (obs=20);
run;



/*****************************************************/
/* CODE TO ASSESS MAIN ST VS. DAVIS ST CTA 'L' USAGE */
/* output will be compared to Metra usage on April 2, 2014 (date of Metra passenger count) */

Proc summary data=CTAevanston (where=(stationname ne '' ));
    class stationname dayOfWeek ;
    var rides dayOfWeek ;
    format dayOfWeek dayfmt.;
    output out=CTAmain mean= std=std_deviation;
run;

Proc summary data=CTAevanston (where=(stationname ne '' ));
    class stationname dayOfWeek ;
    var rides dayOfWeek ;
    format dayOfWeek dayfmt.;
    output out=CTAevanston2 mean= std=std_deviation;
run;

proc sort data=CTAevanston2 ; by dayOfWeek ; run;
proc print data=CTAevanston2 (where=(stationname ne '' and dayOfWeek ne .)) ; run;

/* ONLY LOOKING AT EVANSTON MAIN STREET INFORMATION (BELOW) */
proc print data=CTAevanston2 (where=(stationname eq 'Main' and dayOfWeek ne .)) ; run;

proc sgplot data=CTAevanston2 (where=(stationname ne '' and dayOfWeek ne .));
	series x = dayOfWeek y=rides / markers group=stationname;
run;

proc print data=CTAevanston ;
run;



/*****************************************************/
/* FIND STOPS WITH USAGE COMPARABLE TO EVANSTON MAIN ST */
Proc summary data=CTAweekday ;
    class stationname  ;
    var rides  ;
    format dayOfWeek dayfmt.;
    output out=CTAcomparison mean= std=std_deviation;
run;

/* FIND STATIONS WHERE THE WEEK DAY AVERAGE (ACROSS ALL DAYS OF THE WEEK) FALLS WITHIN THE 
	WEEK DAY AVERAGE +/- THE EVANSTON MAIN ST STD DEV */
Proc summary data=CTAcomparison (where=(rides > (1192-108) and rides < (1192+108)));
    class stationname  ;
    var rides  ;
    format dayOfWeek dayfmt.;
    output out=CTAcomparison2 mean= std=std_deviation;
run;

PROC PRINT data=CTAcomparison2 (where=(stationname ne '' )); run;



/*****************************************************/
/* GETTING A SUMMARY OF "L" STATIONS FOUND ROUGHLY COMPARABLE TO EVANSTON MAIN ST */
Proc summary data=CTAweekday (where=(stationname in ('Main','51st','California-Cermak','Cermak-McCormick Pla','Cicero-Forest Park','Damen-Cermak','Francisco') ));
    class stationname dayOfWeek ;
    var rides dayOfWeek ;
    format dayOfWeek dayfmt.;
    output out=CTAcomparisonAll mean= std=std_deviation;
run;
PROC PRINT data=CTAcomparisonAll (where=(stationname ne '' )); run;

proc sgplot data=CTAcomparisonAll (where=(stationname ne '' and dayOfWeek ne .));
	series x = dayOfWeek y=rides / markers group=stationname;
run;
