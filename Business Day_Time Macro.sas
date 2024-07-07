/************************************************************************************
***** Program: 	Business Day/Time Macro	*****
***** Author:	joshkylepearce			*****
************************************************************************************/

/************************************************************************************
Dataset Creation: Public Holidays
************************************************************************************/

/*Define New Zealand public holidays 2022-2024*/
data public_holidays;
input holiday :date9.;
format holiday date9.;
datalines;
01JAN2022
02JAN2022
06FEB2022
15APR2022
18APR2022
25APR2022
06JUN2022
24JUN2022
26SEP2022
24OCT2022
25DEC2022
26DEC2022
01JAN2023
02JAN2023
03JAN2023
30JAN2023
06FEB2023
07APR2023
10APR2023
25APR2023
05JUN2023
14JUL2023
23OCT2023
25DEC2023
26DEC2023
01JAN2024
02JAN2024
06FEB2024
29MAR2024
01APR2024
25APR2024
03JUN2024
28JUN2024
28OCT2024
25DEC2024
26DEC2024
;
run;

/************************************************************************************
Business Day/Time Macro

Purpose:
Determine whether a date/datetime variable is a business day i.e.
not a weekend or public holiday, and also within user-inputted
business hours (e.g. 9am-5pm).

Input Parameters:
1. 	input_data		- The name of the input dataset.
2. 	date_var		- The name of the date/datetime variable.
3.	business_start	- The first hour of the business day.
4.	business_end	- The last hour of the business day.

Output Parameters:
1. 	business_day	  - Binary indicator. 
2. 	business_day_desc - Text description of business day outcome.

Macro Usage:
1.	Run the public_holidays code.
2.	Run the business_day_time macro code.
3.	Call the business_day_time macro and enter the input parameters.
	e.g. 
	%business_day(
	input_data=work.library,
	date_var=report_date,
	business_start=9,
	business_end=17
	);

Notes:
1. 	business_day=1 indicates date_var is a business day.
2. 	business_day=0 indicates date_var is not a business day.
3. 	business_day_desc outcomes: 
	'Weekend','Public Holiday','Business Day','Outside Business Hours'
4.	date_var must be datetime format since business hour is required.
5.	business_start & business_end compatible with/without quotations
	i.e. business_start = 9 or business_start = "9".
6.	business_start & business_end in 24 hour format i.e. 17 = 5pm.
************************************************************************************/

%macro business_day_time(input_data,date_var,business_start,business_end);

/*Change date/datetime to date9. (DDMMMYYYY) format*/
data date_reformat;
	/*Set input dataset as user-inputted paramter*/
	set &input_data.;
	/*Reformat date/datetime variable for consistency*/
	date_reformat = input(vvalue(&date_var.),anydtdte22.);
	/*Extract weekday from date variable (1=Sunday,...7=Saturday)*/
	weekday=weekday(date_reformat);
	/*Extract hour from date variable (1=1am...23=11pm,24=12am)*/
	hour=hour(&date_var.);
	/*Set format of date as date9. (DDMMMYYYY)*/
	format date_reformat date9.;
run;

/*Check for public holidays*/
proc sql;
create table public_holiday as 
select
	*
	/*Using 2022-2024 NZ public holiday dataset, check each date_var*/
	/*Set a value of 1 for all date_var that match*/
	,case 
		when date_reformat in (select * from public_holidays) then 1 
		else 0 
	end as public_holiday
from 
	date_reformat
;
quit;

/*Create dataset with newly created output parameters*/
data business_day_time;
	set public_holiday;
	/*Initialize business_day variable*/
	business_day=0;
	/*Define format to ensure all characters are included*/
	format business_day_desc $22.;
	/*If weekday=(Saturday,Sunday) then weekend*/
	if weekday in (1,7) then do;
		business_day=0;
		business_day_desc='Weekend';
	end;
	/*If date_var matched public holiday then public holiday*/
	else if public_holiday=1 then do;
		business_day=0;
		business_day_desc='Public Holiday';
	end;
	/*If hour is outside business hours then not within business day*/
	else if hour < &business_start. or hour > &business_end. then do;
		business_day=0;
		business_day_desc='Outside Business Hours';
	end;
	/*If not weekend or public holiday then business day*/
	else do;
		business_day=1;
		business_day_desc='Business Day';
	end;
	/*Keep variables of interest*/
	keep &date_var. business_day business_day_desc;
run;

/*Delete tables that are no longer required*/
proc delete data=date_reformat public_holiday;
run;

%mend;

/************************************************************************************
Example: Data Setup
************************************************************************************/

data datetime_table;
	/*Integer representing datetime 25MAY22:22:55:59*/
	/*Random selection that provides suitable date range*/
	start_date=1969138559;
	/*Create 20 random dates to test usage of the macros*/
	do i=1 to 20;
		date=start_date+(i*100000);
	output;
	end;
	/*Set variable as datetime. format for ease of interpretation*/
	format date datetime.;
	/*Drop variables not required for macro usage*/
	drop start_date i;
run;

/************************************************************************************
Example: Business Day/Time Macro Usage
************************************************************************************/

%business_day_time(
input_data=datetime_table,
date_var=date,
business_start=9,
business_end=17
);