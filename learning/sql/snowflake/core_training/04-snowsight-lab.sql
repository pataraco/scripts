
-- 4.0.0   Snowsight Lab
--         This lab should take approximately 45 minutes.
--         In this lab you will practice logging in to Snowsight, navigating the
--         Snowsight interface, and using its features to gain insights into
--         data.

-- 4.1.0   Connecting to Snowsight
--         In this step you’re going to practice connecting to Snowsight and
--         importing worksheets from the classic console.

-- 4.1.1   Open the WebUI and click the Preview App button:
--         Preview App Button

-- 4.1.2   When the new tab opens, click the Sign in to continue button

-- 4.1.3   Type in the username and password used in class.

-- 4.1.4   You should now see the Worksheets pane. Click the […] button in the
--         upper right hand corner.

-- 4.1.5   A drop down menu should appear. Choose the Import Worksheets option.

-- 4.1.6   You will see an Import Worksheets dialog box. Click the Import button
--         in the dialog box.

-- 4.2.0   Working with worksheets.

-- 4.2.1   Click the + Worksheet in the top right corner.
--         The New Worksheet Button
--         You will be taken to a window with a new worksheet. Next to the home
--         button in the upper left, there is a drop down with the title of the
--         new worksheet in a date-time format. Worksheets are given a title in
--         date-time format by default when created. Now let’s change the
--         worksheet name.

-- 4.2.2   Click on the worksheet name drop down arrow and click on the
--         worksheet name.
--         Renaming the Worksheet

-- 4.2.3   Rename the Worksheet Member List and hit Enter.

-- 4.2.4   In the top right corner, change the worksheet context by selecting a
--         new role and warehouse.
--         At the top left of the worksheet, choose the SnowBearAir_DB database
--         from the Database drop down arrow.
--         Selecting a Database

-- 4.2.5   Now select the warehouse. Choose your animal name warehouse in the
--         upper right hand corner of the UI:
--         Selecting a Warehouse

-- 4.2.6   Now let’s look at the data in a table. Open the Schema section in the
--         lower left hand corner of the UI:
--         Selecting a Schema

-- 4.2.7   On the list of tables on the right hand side, select the
--         modeled.members table.
--         Selecting Modeled.Members

-- 4.2.8   Click the Preview button.
--         Clicking the Preview Button
--         You should now see a pop up window with a preview of the data in the
--         table. To close the Preview window, click outside the preview window.

-- 4.2.9   Click on the modeled.luggage_status table.
--         You should see both tables in the bottom pane.

-- 4.2.10  Click the pin at the top of each table to close.

-- 4.3.0   Write and run a query

-- 4.3.1   Click back to the query screen. The Schema window will stay open
--         until you click the schema button.

-- 4.3.2   Enter the following query into the query screen. Use the hints to
--         fill in the items as they pop up:

SELECT FROM MODELED.MEMBERS M;

--         The query you just entered won’t run on its own because it specifies
--         no columns to be selected. We’ll select the columns in the steps that
--         follow.

-- 4.3.3   Put the cursor after the select and type an M.
--         You should see a pop-up dialog box with a list of columns from the
--         member table as shown below. We’re going to use this feature to add
--         the member ID column and two more columns.
--         Column List

-- 4.3.4   Scroll down to the member_id column and select it.

-- 4.3.5   Now let’s add the first name and last name columns. Type a comma
--         after the member_id column and then M.f to auto-generate a
--         suggestion.
--         You should see the first name column in the list. Click it to add it
--         to the query. Repeat these steps for the last name column. The query
--         should look like this:

SELECT M.member_id, M.firstname, M.lastname FROM modeled.members M;


-- 4.3.6   Now let’s make the query easier to read. Click on the drop down arrow
--         next to the worksheet name and select Format query.
--         Selecting Format Query
--         The query should now appear as it does below.
--         Formatted Query

-- 4.3.7   Click the run button by clicking the blue right pointing arrow in the
--         top right corner of the screen.
--         You should now see the results of the query in the bottom pane.
--         Just above the query results pane, there are four buttons that can be
--         used to control what is visible in the query screen: Query, Results,
--         Chart and Schema. When selected, each shows or hides the different
--         parts of the query screen. Click each and observe the results. Note
--         that query hides the results pane, Results hides the query pane,
--         Chart attempts to chart the data, and Schema displays the schemas and
--         tables.

-- 4.4.0   Working with worksheet history
--         Snowsight offers the ability to preview and re-run previously version
--         of the worksheets. Let’s learn how to work with that feature now.

-- 4.4.1   Modify the query to include the city and state columns and run the
--         query again.

-- 4.4.2   Modify the query again to include the points_balance column and run
--         the query again.

-- 4.4.3   Now that we have a worksheet history to examime, click on the drop
--         down arrow below the blue run arrow.
--         Note that there are several time slots now.

-- 4.4.4   For any of the time slot entries, float your arrow to the right of
--         the entry to see the preview link.

-- 4.4.5   Next, float your arrow over the link to see a preview of the SQL
--         language for the query represented by that time slot.
--         Previewing a Query Previously Run
--         Select a previous entry to see the query results again. FInally,
--         click back to the current query.

-- 4.5.0   Change the sort order of a column.
--         Each column offers an ellipsis next to the column name for sorting.
--         Let’s try sorting now.

-- 4.5.1   Click in the top of the State column to select the column.

-- 4.5.2   Click the ellipsis (…).
--         A box should appear with down and up arrows. Click these to change
--         the sort order of the column.
--         Now click in the top of the points_balance. Change the order of the
--         column and try changing the Show Thousands separators.

-- 4.6.0   Create a second Worksheet with another query
--         Now let’s learn how to create new worksheets.

-- 4.6.1   Click on the Home button in the upper left hand corner.
--         You should be back at the home screen and a list of worksheets should
--         be displayed.

-- 4.6.2   From the home screen, click the blue + Worksheet button in the upper
--         right hand corner.
--         A new empty worksheet should be displayed.

-- 4.6.3   Rename the worksheet to Points for Members and add in the following
--         query:

SELECT m.age, 
count(*) AS member_cnt, 
sum(points_balance) as points_sum,
(points_sum / member_cnt)::integer as member_avg 
FROM MODELED.MEMBERS M
     GROUP BY 1;


-- 4.6.4   Click the drop down arrow next to the query name and select Format
--         query.

-- 4.6.5   Click the run button. (Arrow in the top right corner of the screen)

-- 4.7.0   Using the Automatic Contextual Statistics section
--         Now we’ll practice applying statistical filters to the query we just
--         ran. These filters can be used to quickly gain insights into the
--         result set.
--         In a nutshell, the way filters work is that you select a column and
--         will be presented with an interactive graph to filter the data. Let’s
--         walk through this step by step.

-- 4.7.1   Locate the filters pane to the right of the result pane and click the
--         member_avg column graph.
--         Member Average filter
--         All available columns except for the member average column should
--         have been hidden in the filter pane. You should now see an
--         interactive bar graph labeled Column MEMBER_AVG in the filter pane.
--         Click the last bar in the graph to further filter the data:
--         Filtering by the last bar in the Member Average graph
--         The data should now be filtered as shown below:
--         Member Average when filtered

-- 4.7.2   Now click the Clear filter button in the filter pane.
--         All four columns should be shown now, and the Member Avg column
--         should be highlighted.

-- 4.7.3   Click on each column header and note how the column you clicked is
--         highlighted and a new column filter graph is shown.

-- 4.7.4   Practice filtering on each column as you did above.
--         For example, select the MEMBER_CNT filter. How many ages are in the
--         highest member count? HINT: Click the longest bar in the filter.

-- 4.8.0   Creating a folder and adding worksheets into the folder
--         Now we’ll practice organizing worksheets into folders. The ability to
--         organize worksheets in folders was designed to make it easier for you
--         to group worksheets into logical topics and thus be able to locate
--         what you need quickly.
--         The way this works is that you can create folders within the root of
--         the Worksheets pane and add worksheets to those folders. Let’s
--         practice that now.

-- 4.8.1   Click the home button.

-- 4.8.2   Click the ellipsis (…) next to the +Worksheet button.
--         New Folder button

-- 4.8.3   Name the folder Members Queries and create the folder.
--         Note the Members Queries folder name at upper left hand portion of
--         the worksheets pane. You are now in that folder. Now we’re going to
--         add a worksheet to this folder.

-- 4.8.4   Click Worksheets above Member Queries to return to the root of the
--         Worksheets pane.
--         You are now at the root of the Worksheets pane. Note that there are
--         four tabs beneath the Worksheets title: Recent, Shared with me, My
--         Worksheets and Folders. By using My Worksheets and Folders, you can
--         navigate to your worksheets, select one and add it to a folder, then
--         navigate to the folder to see the worksheet.

-- 4.8.5   Click the My Worksheets tab.

-- 4.8.6   Select the Members List worksheet.

-- 4.8.7   You should now see the contents of the Members List worksheet, to
--         include the SQL code and perhaps the results.

-- 4.8.8   Click the drop down arrow next to the worksheet name and select Move
--         to and the Members Queries folder.
--         Move To Members Queries

-- 4.8.9   Repeat the steps to move the Points for Members query into the
--         Members Queries folder.

-- 4.8.10  Click the Members Queries folder link in the bread crumb trail to
--         check if the two queries are in the folder.
--         Checking the Members Queries folder

-- 4.9.0   Sharing a worksheet
--         Snowflake has created the ability to share worksheets with other
--         users. The idea is that data analysts, data engineers, or even admins
--         could write SQL code to accomplish very specific goals and tasks, and
--         then share that code with colleagues. Let’s learn how to do that now.

-- 4.9.1   Return to the home screen.

-- 4.9.2   Create a new worksheet.

-- 4.9.3   Using the skills you’ve learned, write a simple query. For example,
--         select member_id and points_balance from the members table and limit
--         the results to 10 rows.

-- 4.9.4   Name the worksheet  Shared WS.

-- 4.9.5   Click on the Share button.
--         Share button
--         You should see a dialog box like the one below:
--         Share dialog box

-- 4.9.6   Select another user in the class to share by typing their user name
--         in the text box. HINT: If you don’t know someone else in the class,
--         go back to the classic web UI and view the WebUI -> History tab to
--         find another user.
--         If you need help, ask your instructor.

-- 4.10.0  Using a filter
--         Now let’s practice adding filters to a query and passing values into
--         the filter parameters.

-- 4.10.1  Create a new worksheet named Query Filter.
--         Create the following query in the worksheet:

SELECT m.firstname, m.lastname, m.points_balance, m.started_date FROM modeled.members m
    WHERE m.started_date = :daterange;

--         Once you put the SQL code into the query pane, the Date Range button
--         should appear above with the text Last Day.

-- 4.10.2  Click the Date Range button.
--         You should see the following dialog box:
--         Query filter dialog box

-- 4.10.3  Navigate as shown to choose a custom date range and set the range
--         from 01-20-2019 to 10-06-2020 and click the Apply button to run the
--         query.
--         You should see results in the result pane. Practice using the column
--         filters to the right of the results pane to gain further insight into
--         the data.

-- 4.11.0  Working with charts using a GROUP BY Query.
--         Now let’s practice using the charting function.

-- 4.11.1  Return home and select the Points for Members worksheet.

-- 4.11.2  Select the Chart button.
--         Note that you have a line chart and that the Chart dialog box has
--         appeared to the right.
--         You should see Line for Chart type. Click on the drop down arrow next
--         to Line. You should see options for Line, Bar, Scatter, Heatgrid and
--         Scorecard.
--         Now let’s modify the Data section of the Chart dialog box.

-- 4.11.3  Set the X-Axis to Age.

-- 4.11.4  Set the Data selection to Member_avg.

-- 4.11.5  Change the look of the chart by clicking on each option in the
--         Appearance section of the Chart dialog box.

-- 4.11.6  Switch to a Bar chart.
--         Notice the X-Axis stays as Age but the value for the bars changes to
--         Age sum.

-- 4.11.7  Switch the X-Axis back to Member_avg.
--         Notice that now you have bars for each age.

-- 4.11.8  Float your arrow over each bar to see the value.
--         Change the different Aggregation options.

-- 4.12.0  Working with charts with a query without a GROUP BY.
--         This is similar to the previous exercise except your SQL statement
--         won’t have a GROUP BY clause.

-- 4.12.1  Create a new worksheet named Members Name List.

-- 4.12.2  Add the following query into the worksheet and run the query:

SELECT
    (m.firstname || ' ' || m.lastname) as Name,
    m.age,
    m.state,
    m.city,
    m.started_date,
    m.points_balance
FROM
    modeled.members m;


-- 4.12.3  Select Chart, then change the Chart type to Bar.

-- 4.12.4  Change the Data from Age to Points_Balance and set the Aggregation to
--         Sum.

-- 4.12.5  Select labels for both axes.

-- 4.12.6  Change the different Aggregation options in the Data .

-- 4.12.7  Hover the cursor over various bars in the bar chart and observe that
--         the details for that data are shown.

-- 4.12.8  Try the follow changes to observe the results:
--         Change the X-Axis to Age.
--         Change the Orientation .
--         Change the Order bars by selection.
--         Change the Orientation back.

-- 4.13.0  Working with a date field as the X-Axis

-- 4.13.1  Change the X-Axis to Started_Date.
--         Notice the X-Axis label doesn’t change and has to be changed
--         manually.

-- 4.14.0  Downloading a chart

-- 4.14.1  Using the month chart from the last section, Click the Download Chart
--         button in the top right corner. This is an arrow with a line under
--         it.
--         Downloading a Chart

-- 4.14.2  Click on the file at the bottom of the browser to open and view it.
--         NOTE: This downloads a .png file. This file can be opened in Paint.

-- 4.15.0  Creating a Dashboard

-- 4.15.1  Using the worksheet with the chart from the last section create a new
--         dashboard as shown in the steps below:
--         Creating a New Dashboard

-- 4.15.2  Name the dashboard Member Charts and create the dashboard.
--         You should now see a screen you are already familiar with. This is
--         where the chart can be edited.

-- 4.15.3  Locate the Return to Member Charts Link at the top of the page and
--         click it.
--         You should now see the dashboard itself in read only mode.

-- 4.15.4  In the dashboard, select the ellipse (…) in the top right corner and
--         select View Chart to enter edit mode.

-- 4.15.5  Under data, click on the drop down arrow next to the X-Axis field
--         STARTED_DATE. Under Bucketing, select quarter to display quarters.
--         Change the X-Axis label to read Quarters instead of STARTED_DATE.

-- 4.15.6  Now let’s practice making another chart. Click Return to Member
--         Charts at the top, click the home button, click the My Worksheets
--         tab, then select the Points for Members worksheet.

-- 4.15.7  Select the Chart and create a bar chart with Age as the X-Axis and
--         Member_avg as the bars. Make sure the labels are correct.

-- 4.15.8  Click on the Worksheet name drop down arrow and select Move to ->
--         Member Charts in the dashboards.

-- 4.15.9  Click Return to Member Charts at the top of the screen.

-- 4.15.10 Move the two charts by selecting one and dragging it where you would
--         like it to be.

-- 4.16.0  Working with the Data section
--         The data section of the home page’s left hand navigation bar allows
--         you to view what data is available to you. Let’s familiarize
--         ourselves with that section.

-- 4.16.1  Return to the home page.

-- 4.16.2  In the left hand navigation bar, select the Data->Databases option
--         from the menu.

-- 4.16.3  Select your class database and a schema.

-- 4.16.4  Click on Tables.

-- 4.16.5  Select a table from the list and look at the Details and the columns.
--         Notice the options in the schema to view all the database objects
--         including functions and stored procedures.

-- 4.16.6  Return to a worsheet and Suspend and resize the warehouse

ALTER WAREHOUSE LEARNING SET WAREHOUSE_SIZE=XSmall;
ALTER WAREHOUSE LEARNING SUSPEND;

