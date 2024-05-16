/* Data Analysis and Business Intelligence Project | MySQL Workbench

In this project, I will be roleplaying as a newly hired Database Analyst for Maven Fuzzy Factory, 
an eCommerce start-up, and will be working directly with the CEO, Marketing Director and Website Manager 
to help grow the business and analyze performance along the way 

The database schema can be viewed through this photo link : https://ibb.co/TtcLGym

Business Concepts covered :  
Traffic Source Analysis |  Landing Page Performance & Testing |  Channel Portfolio Optimization |  Product Level Website Analysis |  Analyze Repeat Behavior  


The database has 6 tables representing data from March 2012 – May 2015 

	Order_item_refunds 

	Order_items 

	Orders 

	Products 

	Website_pageviews 

	Website_sessions 

Source:  
https://www.udemy.com/course/advanced-sql-mysql-for-analytics-business-intelligence/?src=sac&kw=advance+sql */


-- I have moved Section 5 here at the beginning to showcase the most recent skills learned. Normal order of sections continues after Section 5.

------------------------------------------ SECTION FIVE : PRODUCT ANALYSIS --------------------------------------------------

/* Assignment 5.1 : Product-level Sales Analysis. Received: 2013-01-04. CEO: About to launch a new product and would want to do 
a deep dive on the current flagship product. Pull monthly trends to date for number of sales, total revenue, 
and total margin generated for the business. */

SELECT
	 YEAR(created_at) AS year,
	 MONTH(created_at) AS month,
	 COUNT(DISTINCT order_id) AS number_of_sales,
	 SUM(price_usd) AS total_revenue,
	 SUM(price_usd - cogs_usd) AS total_margin
FROM 
	 orders
WHERE 
	 created_at < '2013-01-04'
GROUP BY 1, 2;


/* Assignment 5.2 : Analyzing Product Launches. Received: 2013-04-03. CEO: Second product launched on 2013-01-06. 
Pull monthly order volume, overall conversion rates, revenue per session, and a breakdown of sales by product 
for the time period since 2012-04-01. */

SELECT
	 YEAR(website_sessions.created_at) AS year,
	 MONTH(website_sessions.created_at) AS month,
	 COUNT(DISTINCT orders.order_id) AS orders,
	 COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
	 SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
	 COUNT(DISTINCT CASE WHEN orders.primary_product_id = 1 THEN orders.order_id ELSE NULL END) AS product_one_orders,
	 COUNT(DISTINCT CASE WHEN orders.primary_product_id = 2 THEN orders.order_id ELSE NULL END) AS product_two_orders
FROM 
	 website_sessions
LEFT JOIN 
	 orders
	 ON orders.website_session_id = website_sessions.website_session_id
WHERE 
	 website_sessions.created_at BETWEEN '2012-04-01' AND '2013-04-03'
GROUP BY 1, 2;

-- Conversion rates and revenue per session are improving over time
-- CEO wants to understand if growth was due to the new product launch or merely a continuation of overall business improvements


/* Assignment 5.3 : Product-level Website Pathing. Received: 2013-04-06. Website Manager: Look at sessions 
which hit the /products page and see where they went next. Pull clickthrough rates from /products since 
the second product launch and compare to the 3 months leading up to launch as baseline. */

-- First, create a temporary table for the conversion funnels
CREATE TEMPORARY TABLE session_level_viewed_flags
SELECT
	 website_session_id,
	 MAX(products) AS products_viewed,
	 MAX(mrfuzzy) AS mrfuzzy_viewed,
	 MAX(lovebear) AS lovebear_viewed
FROM (
	SELECT
		 created_at,
		 website_session_id,
		 pageview_url,
		 CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products,
		 CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy,
		 CASE WHEN pageview_url = '/the-forever-love-bear' THEN 1 ELSE 0 END AS lovebear
	FROM 
		 website_pageviews
	WHERE 
		 created_at BETWEEN '2012-10-06' AND '2013-04-06'
) AS pageview_level
GROUP BY 1;
-- end of temp table

-- Second, summarize the pathing grouped by time period
SELECT
	 CASE
	 	WHEN website_pageviews.created_at < '2013-01-06' THEN 'A. Pre_Product_2'
	 	WHEN website_pageviews.created_at >= '2013-01-06' THEN 'B. Post_Product_2'
	 END AS time_period,
	 
	 COUNT(DISTINCT CASE WHEN products_viewed = 1 THEN session_level_viewed_flags.website_session_id ELSE NULL END) AS sessions,
	 COUNT(DISTINCT CASE WHEN mrfuzzy_viewed + lovebear_viewed > 0 THEN session_level_viewed_flags.website_session_id ELSE NULL END) AS w_next_pg,

	 COUNT(DISTINCT CASE WHEN mrfuzzy_viewed + lovebear_viewed > 0 THEN session_level_viewed_flags.website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN products_viewed = 1 THEN session_level_viewed_flags.website_session_id ELSE NULL END) AS pct_w_next_pg,

	 COUNT(DISTINCT CASE WHEN products_viewed = 1 AND mrfuzzy_viewed = 1 THEN session_level_viewed_flags.website_session_id ELSE NULL END) AS to_mrfuzzy,
	 COUNT(DISTINCT CASE WHEN products_viewed = 1 AND mrfuzzy_viewed = 1 THEN session_level_viewed_flags.website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN products_viewed = 1 THEN session_level_viewed_flags.website_session_id ELSE NULL END) AS pct_to_mrfuzzy,

	 COUNT(DISTINCT CASE WHEN products_viewed = 1 AND lovebear_viewed = 1 THEN session_level_viewed_flags.website_session_id ELSE NULL END) AS to_lovebear,
	 COUNT(DISTINCT CASE WHEN products_viewed = 1 AND lovebear_viewed = 1 THEN session_level_viewed_flags.website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN products_viewed = 1 THEN session_level_viewed_flags.website_session_id ELSE NULL END) AS pct_to_lovebear
FROM 
	 session_level_viewed_flags
LEFT JOIN 
	 website_pageviews
	 ON session_level_viewed_flags.website_session_id = website_pageviews.website_session_id
GROUP BY 1;

RESULT:

time_period		sessions	w_next_pg	pct_w_next_pg	to_mrfuzzy	pct_to_mrfuzzy	to_lovebear	pct_to_lovebear
A. Pre_Product_2	15696		11347		0.7229		11347		0.7229		0		0.0000
B. Post_Product_2	10710		8201		0.7657		6655		0.6214		1546		0.1444


-- While conversion rates from /products pageviews that clicked through to Mr. Fuzzy have decreased since Love Bear launched, 
-- overall clickthrough rate has gone up, indicating additional overall product interest
-- Should probably look at conversion funnels for each product individually


/* Assignment 5.4 : Building Product-level Conversion Funnels. Received: 2013-04-10
Website Manager: Analyze the conversion funnels from each of the two products from product page to conversion since January 6. 
Produce a comparison between the two conversion funnels for all website traffic. */

-- Gather the relevant sessions and pageviews
CREATE TEMPORARY TABLE sessions_w_product_seen
SELECT
	 website_session_id,
	 website_pageview_id,
	 pageview_url AS product_seen
FROM 
	 website_pageviews
WHERE 
	 created_at BETWEEN '2013-01-06' AND '2013-04-10' -- date of product launch and request
	 AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear') -- sessions on the two product pages;
-- end of temp table

-- finding the right pageview_urls to build the conversion funnels
SELECT DISTINCT
	 website_pageviews.pageview_url
FROM 
	 sessions_w_product_seen
LEFT JOIN 
	 website_pageviews
	 ON website_pageviews.website_session_id = sessions_w_product_seen.website_session_id -- limiting to sessions on product pages
	 AND website_pageviews.website_pageview_id > sessions_w_product_seen.website_pageview_id; -- show urls after the product pages
-- pageview_urls viewed after both products: /cart, /shipping, /billing-2, /thank-you-for-your-order

-- building the conversion funnels
CREATE TEMPORARY TABLE session_product_conversion_funnel
SELECT
	 website_session_id,
	 CASE
		 WHEN product_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
		 WHEN product_seen = '/the-forever-love-bear' THEN 'lovebear'
		 ELSE 'check logic'
	 END AS product_seen,
	 MAX(cart) AS cart,
	 MAX(shipping) AS shipping,
	 MAX(billing) AS billing,
	 MAX(thankyou) AS thankyou
FROM (
SELECT
	 sessions_w_product_seen.website_session_id,
	 sessions_w_product_seen.product_seen,
	 CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
	 CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
	 CASE WHEN website_pageviews.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing,
	 CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou
FROM 
	 sessions_w_product_seen
LEFT JOIN 
	 website_pageviews
	 ON website_pageviews.website_session_id = sessions_w_product_seen.website_session_id -- limiting to sessions on product pages
	 AND website_pageviews.website_pageview_id > sessions_w_product_seen.website_pageview_id -- show urls after the product pages
) AS tableAlias

GROUP BY 1, 2;
-- end of temp table

-- Summarizing the conversion funnel for both products
SELECT
	 product_seen,
	 COUNT(website_session_id) AS sessions,
	 COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) AS to_cart,
	 COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
	 COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) AS to_billing,
	 COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM 
	 session_product_conversion_funnel
GROUP BY 1;

RESULT:

product_seen	sessions	to_cart		to_shipping	to_billing	to_thankyou
lovebear	1599		877		603		488		301
mrfuzzy		6985		3038		2084		1710		1088


-- Calculating click through rates
SELECT
	 product_seen,

	 COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) /
		COUNT(website_session_id) AS product_click_rt,

	 COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,

	 COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,

	 COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM 
	 session_product_conversion_funnel
GROUP BY 1;

RESULT:

product_seen	product_click_rt	cart_click_rt	shipping_click_rt	billing_click_rt
lovebear	0.5485			0.6876		0.8093			0.6168
mrfuzzy		0.4349			0.6860		0.8205			0.6363


-- Adding a second product increased overall CTR from the /products page and Love Bear has a better click rate 
-- to the /cart page and has comparable rates with Mr Fuzzy throughout the rest of the funnel
-- Second product has been good for business, might consider adding a third product


/* Assignment 5.5 : Cross-Sell Analysis. Received: 2013-11-22
CEO: On September 25, customers were given the option to add a second product while on the /cart page. 
Compare the month before vs. the month after the change. Show clickthrough rate from the /cart page, 
average products per order, average order value, and overall revenue per /cart pageview. */

-- gathering the sessions on the /cart page
CREATE TEMPORARY TABLE sessions_on_cart
SELECT
	 website_session_id AS cart_session_id,
	 website_pageview_id AS cart_pv,
	 CASE
		 WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
		 WHEN created_at >= '2013-09-25' THEN 'B. Post_Cross_Sell'
	 END AS time_period
FROM 
	 website_pageviews
WHERE 
	 created_at BETWEEN '2013-08-25' AND '2013-10-25'
	 AND pageview_url = '/cart';
-- end of temp table

-- gathering sessions viewing pages after /cart
CREATE TEMPORARY TABLE sessions_after_cart
SELECT
	 sessions_on_cart.cart_session_id AS after_cart_id,
	 sessions_on_cart.time_period,
	 MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM 
	 sessions_on_cart
LEFT JOIN 
	 website_pageviews
	 ON website_pageviews.website_session_id = sessions_on_cart.cart_session_id
	 AND website_pageviews.website_pageview_id > sessions_on_cart.cart_pv -- grabbing pvs after seeing /cart
GROUP BY 1, 2
HAVING 
	 MIN(website_pageviews.website_pageview_id) IS NOT NULL; -- eliminate bounce sessions after /cart
-- end of temp table

-- gathering the sessions on /cart that converted to orders
CREATE TEMPORARY TABLE cart_sessions_w_orders
SELECT
	 time_period,
	 cart_session_id AS cart_order_id,
	 order_id,
	 items_purchased,
	 price_usd
FROM 
	 sessions_on_cart
INNER JOIN 
	 orders
	 ON orders.website_session_id = sessions_on_cart.cart_session_id;
-- end of temp table

-- finally, summarizing the data grouped by time period
SELECT
	 time_period,
	 COUNT(DISTINCT cart_session_id) AS cart_sessions,
	 SUM(clicked_after_cart) AS clickthroughs,
	 SUM(clicked_after_cart) / COUNT(DISTINCT cart_session_id) AS cart_ctr,
	 -- SUM(ordered) AS orders_placed,
	 -- SUM(items_purchased) AS products_purchased,
	 SUM(items_purchased) / SUM(ordered) AS products_per_order,
	 ROUND((SUM(price_usd) / SUM(ordered)), 4) AS avg_order_value,
	 ROUND((SUM(price_usd) / COUNT(DISTINCT cart_session_id)), 4) AS rev_per_cart_session
FROM (
SELECT
	 sessions_on_cart.time_period,
	 sessions_on_cart.cart_session_id,
	 -- sessions_after_cart.after_cart_id,
	 CASE WHEN sessions_after_cart.after_cart_id IS NOT NULL THEN 1 ELSE 0 END AS clicked_after_cart,
	 -- cart_sessions_w_orders.cart_order_id,
	 CASE WHEN cart_sessions_w_orders.cart_order_id IS NOT NULL THEN 1 ELSE 0 END AS ordered,
	 cart_sessions_w_orders.items_purchased,
	 cart_sessions_w_orders.price_usd
FROM 
	 sessions_on_cart
LEFT JOIN 
	 sessions_after_cart
	 ON sessions_after_cart.after_cart_id = sessions_on_cart.cart_session_id
LEFT JOIN 
	 cart_sessions_w_orders
	 ON cart_sessions_w_orders.cart_order_id = sessions_on_cart.cart_session_id
) AS tableAlias

GROUP BY 1;

RESULT:

time_period		cart_sessions	clickthroughs	cart_ctr	products_per_order	avg_order_value		rev_per_cart_session
A. Pre_Cross_Sell	1830		1229		0.6716		1.0000			51.4164			18.3188
B. Post_Cross_Sell	1975		1351		0.6841		1.0447			54.2518			18.4319


-- Looks like clickthrough rate from the /cart page did not go down, and products per order, average order value, and revenue per /cart session are all up since the addition of cross-selling


/* Assignment 5.6 : Product Portfolio Expansion. Received: 2014-01-12
CEO: On December 12, a third product was launched targeting the birthday gift market (Birthday Bear). 
Run a pre-post analysis comparing the month before vs. the month after, in terms of 
session-to-order conversion rate, AOV, products per order, and revenue per session */

SELECT
	 CASE
	 	WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
	 	WHEN website_sessions.created_at >= '2013-12-12' THEN 'B. Post_Birthday_Bear'
	 END AS time_period,
	 -- COUNT(DISTINCT website_session_id) AS sessions,
	 -- COUNT(DISTINCT order_id) AS orders,
	 COUNT(DISTINCT order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
	 ROUND((SUM(price_usd) / COUNT(DISTINCT order_id)), 4) AS avg_order_value,
	 SUM(items_purchased) / COUNT(DISTINCT order_id) AS products_per_order,
	 ROUND((SUM(price_usd) / COUNT(DISTINCT website_sessions.website_session_id)), 4) AS rev_per_session
FROM 
	 website_sessions
LEFT JOIN 
	 orders
	 ON orders.website_session_id = website_sessions.website_session_id
WHERE 
	 website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;

RESULT:

time_period		conv_rate	avg_order_value		products_per_order	rev_per_session
A. Pre_Birthday_Bear	0.0608		54.2265			1.0464			3.2987
B. Post_Birthday_Bear	0.0702		56.9313			1.1234			3.9988

-- Looks like adding a third product has been good for the business, all metrics are up


/* Assignment 5.7 : Analyzing Product Refund Rates. Received: 2014-10-14
CEO: The Mr Fuzzy supplier had some quality issues that weren't corrected until September 2013, 
then a major problem when the bears' arms were falling off in August/September 2014. 
A new supplier was contracted on September 16, 2014. Pull monthly product refund rates, by product, 
and confirm whether quality issues have been fixed. */

SELECT
	 YEAR(order_items.created_at) AS yr,
	 MONTH(order_items.created_at) AS mo,

	 COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
	 COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_item_refund_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_refund_rt,
        
	 COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,    
	 COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_item_refund_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_refund_rt,
        
	 COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
	 COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_item_refund_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_refund_rt,
        
	 COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
	 COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_item_refund_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_refund_rt
FROM 
	 order_items
LEFT JOIN 
	 order_item_refunds
	 ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE 
	 order_items.created_at <= '2014-10-14'
GROUP BY 1, 2;
	
-- Refund rates for Mr. Fuzzy did go down after the initial improvements in September 2013 but became especially bad in August and September 2014 as expected (13-14%)
-- New supplier is better so far and refund rates are lower overall across all products


------------------------------------------ SECTION ONE : ANALYZING TRAFFIC SOURCES --------------------------------------------------

/* Assignment 1.1 : Identifying top traffic sources in terms of website sessions, grouped by UTM source, campaign, and referring domain */

SELECT
          utm_source,
          utm_campaign,
          http_referer,
          COUNT(DISTINCT website_session_id) AS sessions
FROM 
          website_sessions
WHERE 
          created_at < '2012-04-12'
GROUP BY 
          1, 
          2, 
          3
ORDER BY 4 DESC;


/* Assignment 1.2 : Calculate conversion rates from sessions to orders up until 2012-04-14 */

SELECT
          COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
          COUNT(DISTINCT orders.order_id) AS orders,
          COUNT(DISTINCT orders.order_id) / 
		COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate
FROM 
          website_sessions
LEFT JOIN 
          orders
          ON website_sessions.website_session_id = orders.website_session_id
WHERE 
          website_sessions.created_at < '2012-04-14'
	  AND utm_source = 'gsearch'
	  AND utm_campaign = 'nonbrand';

-- Based on this analysis, Marketing is overspending based on the conversion rate (less than 4%), recommend Marketing Director to dial down on search bids, thereby reducing company costs


/* Assignment 1.3 : Based on the previous analysis, Marketing bid down on gsearch nonbrand (utm source and campaign) last 2012-04-15.
Pull gsearch nonbrand trended session volume by week to see if these bid changes have caused volume to drop. */

SELECT
          MIN(DATE(created_at)) AS week_start_date,
          COUNT(DISTINCT website_session_id) AS sessions
FROM 
          website_sessions
WHERE 
          created_at < '2012-05-10' -- date of receipt of assignment
	  AND utm_source = 'gsearch'
	  AND utm_campaign = 'nonbrand'
GROUP BY 
	  YEAR(created_at),
          WEEK(created_at);

-- UTM source gsearch seems fairly sensitive to bid changes since the number of sessions have dropped.
-- Moving forward, need to think of ways to make campaigns more efficient to maximize volume while saving costs


/* Assignment 1.4 : Bid Optimization for Paid Traffic. Investigate conversion rates from sessions to orders by device type (desktop or mobile)
to determine whether we need to bid up on either */

SELECT
	  device_type,
          COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
          COUNT(DISTINCT orders.order_id) AS orders,
          COUNT(DISTINCT orders.order_id) / 
		COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate
FROM 
          website_sessions
LEFT JOIN 
          orders
	  ON website_sessions.website_session_id = orders.website_session_id
WHERE 
          website_sessions.created_at < '2012-05-11'
          AND utm_source = 'gsearch'
          AND utm_campaign = 'nonbrand'
GROUP BY 
          1;

-- Result: desktop sessions have 3.7% conversion rate versus mobile at only 1%
-- Recommend to increase bids on desktop to rank higher in auctions and lead to sales boosts


/* Assignment 4.5 : Trending with Granular Segments. Based on the previous analysis, gsearch nonbrand campaigns
were bid up on 2012-05-19. Pull weekly trends for both desktop and mobile to see the impact on volume. 
Use 2012-04-15 until the bid change as the baseline. */

SELECT
	  MIN(DATE(created_at)) AS week_start_date,
          COUNT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions,
          COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions
FROM 
          website_sessions
WHERE 
          created_at BETWEEN '2012-04-15' AND '2012-06-09'
	  AND utm_source = 'gsearch'
          AND utm_campaign = 'nonbrand'
GROUP BY
	  YEAR(created_at),
          WEEK(created_at);

-- Desktop performance is looking strong due to bid changes based on the previous conversion analysis. 


------------------------------------------ SECTION TWO : ANALYZING WEBSITE PERFORMANCE --------------------------------------------------

/* Assignment 2.1 : Finding top website pages. Pull the most viewed website pages ranked by session volume */

SELECT
          pageview_url,
          COUNT(DISTINCT website_pageview_id) AS pageviews
FROM 
	  website_pageviews
WHERE 
	  created_at < '2012-06-09'
GROUP BY 
	  pageview_url
ORDER BY 
	  pageviews DESC;

-- The homepage, products page, and Mr. Fuzzy page receive the most traffic


/* Assignment 2.2 : Finding top entry pages. Pull all entry or landing pages and rank them on entry volume */

-- First, return the first pageview for each website session and transform the query result into a temporary table

CREATE TEMPORARY TABLE entry_pageviews
SELECT
	  website_session_id,
	  MIN(website_pageview_id) AS entry_pageview_id
FROM 
	  website_pageviews
WHERE 
	  created_at < '2012-06-12'
GROUP BY 
	  website_session_id;

-- end of temp table

-- Then query the temporary table to return the landing pages with their session volume 

SELECT
	  pageview_url AS landing_page,
	  COUNT(DISTINCT entry_pageviews.website_session_id) AS sessions_hitting_landing_page
FROM 
	  entry_pageviews
LEFT JOIN 
	  website_pageviews
	  ON entry_pageviews.entry_pageview_id = website_pageviews.website_pageview_id
GROUP BY 
	  pageview_url;

-- It looks like all traffic comes through the /home page at this point in time


/* Assignment 2.3 : Calculating Bounce Rates. Pull the bounce rates for traffic landing on the /home page. 
Show sessions, bounced sessions, and the bounce rate. */

-- First, create a temporary table grouping website sessions with their first pageviews
CREATE TEMPORARY TABLE first_pgviews
SELECT
	  website_session_id,
	  MIN(website_pageview_id) AS first_pageview_id
FROM 
	  website_pageviews
WHERE 
	  created_at < '2012-06-14'
GROUP BY 
	  website_session_id;
-- end of temp table

-- Second, create a temporary table showing website sessions with the landing page (first pageview)
CREATE TEMPORARY TABLE sessions_w_home_landing_page
SELECT
	  first_pgviews.website_session_id,
	  website_pageviews.pageview_url AS landing_page
FROM 
	  first_pgviews
LEFT JOIN 
	  website_pageviews
	  ON first_pgviews.first_pageview_id = website_pageviews.website_pageview_id
WHERE 
	  pageview_url = '/home';
-- end of temp table

-- Third, create a temporary table with the bounce sessions for the /home page or those website sessions that did
go further than the /home page or stopped at the /home page
CREATE TEMPORARY TABLE bounced_sessions
SELECT
	  sessions_w_home_landing_page.website_session_id,
	  sessions_w_home_landing_page.landing_page,
	  COUNT(website_pageviews.website_pageview_id) AS count_pages_viewed
FROM 
	  sessions_w_home_landing_page
LEFT JOIN 
	  website_pageviews
	  ON sessions_w_home_landing_page.website_session_id = website_pageviews.website_session_id
GROUP BY 
	  sessions_w_home_landing_page.website_session_id,
	  sessions_w_home_landing_page.landing_page
HAVING 
	  COUNT(website_pageviews.website_pageview_id) = 1; -- bounce sessions are those whose pageview count is 1
-- end of temp table

-- Calculate the bounce sessions and bounce rate by left joining the two previous temporary tables
SELECT
	  COUNT(sessions_w_home_landing_page.website_session_id) AS sessions,
	  COUNT(bounced_sessions.website_session_id) AS bounced_sessions,
	  COUNT(bounced_sessions.website_session_id) / 
	  	COUNT(sessions_w_home_landing_page.website_session_id) AS bounce_rate
FROM 
	  sessions_w_home_landing_page
LEFT JOIN 
	  bounced_sessions
	  ON sessions_w_home_landing_page.website_session_id = bounced_sessions.website_session_id;

-- From this analysis, there is a high bounce rate at almost 60% for paid search w/c should be high-quality traffic
-- Note that all sessions so far have the homepage as the landing page and 60% of all sessions end here
-- Keep an eye on bounce rates, which represent a major area of improvement 
-- Help the Website Manager measure and analyze a new page that she thinks will improve performance, and analyze the results of an A/B split test against the homepage


/* Assignment 2.4 : Analyzing Landing Page Tests. Based on the analysis, a new custom landing page called /lander-1
was run in a 50/50 test against the homepage (/home) for gsearch non-brand traffic. Pull the bounce rates for the 
two groups to evaluate the new page. Just look at the time period where /lander-1 was getting traffic. */

-- Finding the first instance of /lander-1 to set the analysis timeframe
SELECT
	  MIN(created_at),
	  MIN(website_pageview_id)
FROM 
	  website_pageviews
WHERE 
	  pageview_url = '/lander-1';

-- created_at = '2012-06-19' OR website_pageview_id = 23504

-- First, create a temporary table connecting website sessions with the first pageview id
CREATE TEMPORARY TABLE first_pageviews
SELECT
	  website_pageviews.website_session_id,
	  MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM 
	  website_pageviews
INNER JOIN 
	  website_sessions
	  ON website_sessions.website_session_id = website_pageviews.website_session_id
	  AND website_sessions.created_at < '2012-07-28'
	  AND website_pageviews.website_pageview_id > 23504 -- restriction from the first query
	  AND utm_source = 'gsearch'
	  AND utm_campaign = 'nonbrand'
GROUP BY 
	  website_pageviews.website_session_id;
-- end of temp table

-- Second, create a temporary table connecting website sessions with the /home and /lander-1 as their landing pages
CREATE TEMPORARY TABLE test_sessions_landing_page
SELECT
	  first_pageviews.website_session_id,
	  website_pageviews.pageview_url AS landing_page
FROM 
	  first_pageviews
LEFT JOIN 
	  website_pageviews
	  ON first_pageviews.min_pageview_id = website_pageviews.website_pageview_id
WHERE 
	  website_pageviews.pageview_url IN ('/home', '/lander-1');
-- end of temp table

--  Third, create a temporary table showing the bounce sessions per landing page
CREATE TEMPORARY TABLE nonbrand_bounced_sessions
SELECT
	  test_sessions_landing_page.website_session_id,
	  test_sessions_landing_page.landing_page,
	  COUNT(website_pageviews.website_pageview_id) AS pages_viewed
FROM 
	  test_sessions_landing_page
LEFT JOIN 
	  website_pageviews
	  ON website_pageviews.website_session_id = test_sessions_landing_page.website_session_id
GROUP BY 
	  1, 2
HAVING 
	  COUNT(website_pageviews.website_pageview_id) = 1; -- bounce sessions are those whose pageview count is 1
-- end of temp table

-- Finally, left join previous two tables to show bounce rate comparison between the /home and /lander-1 landing pages
SELECT
	  test_sessions_landing_page.landing_page,
	  COUNT(DISTINCT test_sessions_landing_page.website_session_id) AS total_sessions,
	  COUNT(DISTINCT nonbrand_bounced_sessions.website_session_id) AS bounce_sessions,
	  COUNT(DISTINCT nonbrand_bounced_sessions.website_session_id) / 
		COUNT(test_sessions_landing_page.website_session_id) AS bounce_rate
FROM 
	  test_sessions_landing_page
LEFT JOIN 
	  nonbrand_bounced_sessions
	  ON test_sessions_landing_page.website_session_id = nonbrand_bounced_sessions.website_session_id
GROUP BY 1;

-- The custom lander has a lower bounce rate (53%) vs the homepage (58%)
-- Help the Website Manager confirm that traffic is all running to the new custom lander after campaign updates 
-- Keep an eye on bounce rates and help the team look for other areas to test and optimize


/* Assignment 2.5 : Landing Page Trend Analysis. Pull the volume of paid search nonbrand traffic landing on 
/home and /lander-1 trended weekly from 2012-06-01 and 2012-08-31, and pull overall paid search bounce
rate trended weekly as well */

-- First, creating a temporary table containing the first pageview per website session for /home and /lander-1
CREATE TEMPORARY TABLE landing_pages
SELECT
	  website_sessions.website_session_id,
	  MIN(website_pageview_id) AS min_pageview
FROM 
	  website_pageviews
INNER JOIN 
	  website_sessions
	  ON website_pageviews.website_session_id = website_sessions.website_session_id
	  AND website_sessions.created_at > '2012-06-01'
	  AND website_sessions.created_at < '2012-08-31'
	  AND utm_source = 'gsearch'
	  AND utm_campaign = 'nonbrand'
WHERE 
	  pageview_url IN ('/home', '/lander-1')
GROUP BY 
	website_sessions.website_session_id;
-- end of temp table

-- Second, create a temporary table finding and limiting only to the landing page sessions showing the page url
CREATE TEMPORARY TABLE landing_page_sessions
SELECT
	  landing_pages.website_session_id,
	  website_pageviews.pageview_url AS landing_page
FROM 
	  landing_pages
LEFT JOIN 
	  website_pageviews
	  ON landing_pages.min_pageview = website_pageviews.website_pageview_id;
-- end of temp table

-- Third, creating a temporary table of the bounce sessions per landing page
CREATE TEMPORARY TABLE bounce_table
SELECT
	  landing_page_sessions.website_session_id,
	  landing_page_sessions.landing_page AS landing_page,
	  COUNT(DISTINCT website_pageviews.website_pageview_id) AS pages_viewed
FROM 
	  landing_page_sessions
LEFT JOIN 
	  website_pageviews
	  ON landing_page_sessions.website_session_id = website_pageviews.website_session_id
GROUP BY
	  landing_page_sessions.website_session_id,
	  landing_page_sessions.landing_page
HAVING 
	  COUNT(DISTINCT website_pageviews.website_pageview_id) = 1; -- bounce sessions are those whose pageview count is 1
-- end of temp table

-- Finally, query and left join the three previous tables to show the total volume for /home and /lander-1 and bounce rates all trended weekly
SELECT
	  MIN(DATE(website_pageviews.created_at)) AS week_start_date,
	  -- COUNT(DISTINCT bounce_table.website_session_id),
	  -- COUNT(DISTINCT landing_page_sessions.website_session_id),
	  COUNT(DISTINCT bounce_table.website_session_id) / 
		COUNT(DISTINCT landing_page_sessions.website_session_id) AS bounce_rate,
	  COUNT(DISTINCT CASE WHEN landing_page_sessions.landing_page = '/home' THEN landing_page_sessions.website_session_id ELSE NULL END) AS home_sessions,
	  COUNT(DISTINCT CASE WHEN landing_page_sessions.landing_page = '/lander-1' THEN landing_page_sessions.website_session_id ELSE NULL END) AS lander_sessions
FROM 
	  landing_page_sessions
LEFT JOIN 
	  bounce_table
	  ON landing_page_sessions.website_session_id = bounce_table.website_session_id
LEFT JOIN 
	  website_pageviews
	  ON landing_page_sessions.website_session_id = website_pageviews.website_session_id
GROUP BY
	  YEARWEEK(website_pageviews.created_at);


/* Assignment 2.6 : Building Conversion Funnels. The Website Manager wants to understand where we lose gsearch visitors 
between /lander-1 and placing an order. Build a full conversion funnel, analyzing how many customers make it to each step.
Start with /lander-1 to the thank you page. Use data since August 5 to September 5, 2012. */

-- First, gather the relevant sessions and track pageviews visited using CASE WHEN and use this query as a subquery
-- Second, create a temporary table showing the conversion funnel per website session using the subquery
CREATE TEMPORARY TABLE session_level_made_it_flags
SELECT
	  website_session_id,
	  -- pageview_url,
	  MAX(lander_page) AS lander_made_it,
	  MAX(products_page) AS products_made_it,
	  MAX(mrfuzzy_page) AS mrfuzzy_made_it,
	  MAX(cart_page) AS cart_made_it,
	  MAX(shipping_page) AS shipping_made_it,
	  MAX(billing_page) AS billing_made_it,
	  MAX(thankyou_page) AS thankyou_made_it
FROM (
	SELECT
		  website_sessions.website_session_id,
	    	  website_pageviews.pageview_url,
		  website_pageviews.created_at,
		  CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_page,
		  CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
		  CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
		  CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
		  CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		  CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
		  CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
	FROM 
		  website_sessions
	LEFT JOIN 
		  website_pageviews
		  ON website_sessions.website_session_id = website_pageviews.website_session_id
	WHERE 
		  website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
		  AND website_sessions.utm_source = 'gsearch'
		  AND website_sessions.utm_campaign = 'nonbrand'
	ORDER BY 
		  website_sessions.website_session_id,
		  website_sessions.created_at
) AS pageview_level

GROUP BY 1;
-- end of temp table

-- Third, calculate the click through rates from the temporary table
SELECT
	 -- COUNT(website_session_id) AS sessions,
	 -- COUNT(lander_made_it),
	 COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(website_session_id) AS lander_click_rt,
	 COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
	 COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
	 COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
	 COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
	 COUNT(DISTINCT CASE WHEN  thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM 
	 session_level_made_it_flags;

/* Based on this analysis, I would recommend the Website Manager to focus on the lander, Mr. Fuzzy page, 
and the billing page which have the lowest click rates */


/* Assignment 2.7 : Analyzing Conversion Funnel Tests. Website Manager created a new billing test page called /billing-2.  
Determine whether /billing-2 is doing better than original /billing page. What percent of sessions on those pages end up 
placing an order for all traffic, not just search visitors? */

-- First, find the first instance where /billing-2 was viewed to set the analysis timeframe
SELECT
	 MIN(website_pageview_id) AS first_pv
FROM 
	 website_pageviews
WHERE 
	 pageview_url = '/billing-2';
-- first pageview id = 53550

-- Second, retrieve the relevant pageview urls, sessions, and orders and use the query result as a subquery
-- Third, calculate the session to order conversion rates for the different billing pages
SELECT
	 billing_version_seen,
	 COUNT(DISTINCT website_session_id) AS sessions,
	 COUNT(DISTINCT order_id) AS orders,
	 COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS billing_to_order_rate
FROM (
	SELECT
		 website_pageviews.pageview_url AS billing_version_seen,
		 website_pageviews.website_session_id,
		 orders.order_id
	FROM 
		 website_pageviews
	LEFT JOIN 
		 orders
		 ON website_pageviews.website_session_id = orders.website_session_id
	WHERE 
		 website_pageviews.pageview_url IN ('/billing', '/billing-2')
		 AND website_pageviews.website_pageview_id >= 53550
		 AND website_pageviews.created_at < '2012-11-10'
) AS billing_sessions_w_orders

GROUP BY 1;

-- From this analysis, it seems that the new billing page is doing a better job at converting sessions to orders

------------------------------------------ SECTION THREE : ANALYSIS FOR CHANNEL PORTFOLIO MANAGEMENT --------------------------------------------------

/* Assignment 3.1 : Analyzing Channel Portfolios. With gsearch doing well and the site performing better, 
a second paid search channel, "bsearch", was launched around August 22, 2012. Pull weekly trended session 
volume since then and compare to gsearch nonbrand. */

SELECT
	 MIN(DATE(created_at)) AS week_start_date,
	 COUNT(DISTINCT website_session_id) AS total_sessions,
	 COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
	 COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM
	 website_sessions
WHERE 
	 created_at BETWEEN '2012-08-22' AND '2012-11-29'
	 AND utm_campaign = 'nonbrand'
GROUP BY 
	 YEARWEEK(created_at);

-- bsearch gets roughly a third of the traffic of gsearch, which is significant enough to be better acquainted with the new channel


/* Assignment 3.2 : Comparing Channel Characteristics. Pull the percentage of traffic coming on mobile 
from bsearch and compare to gsearch, aggregate data since August 22. */

SELECT
	 utm_source,
	 COUNT(DISTINCT website_session_id) AS total_sessions,
	 COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
	 COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) / 
		COUNT(DISTINCT website_session_id) AS pct_mobile
FROM 
	 website_sessions
WHERE
	 created_at BETWEEN '2012-08-22' AND '2012-11-29'
	 AND utm_campaign = 'nonbrand'
	 AND utm_source IN ('gsearch', 'bsearch')
GROUP BY
	 utm_source;

-- It looks like the two channels are quite different from a device standpoint, investigate further


/* Assignment 3.3 : Cross-Channel Bid Optimization. Pull nonbrand conversion rates from session to order 
for gsearch and bsearch, and slice the data by device type. Analyze data from August 22 to September 18, 
a special pre-holiday campaign for gsearch started on September 19 so limit to before this date. */

SELECT
	 device_type,
	 utm_source,
	 COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	 COUNT(DISTINCT orders.order_id) AS orders,
	 COUNT(DISTINCT orders.order_id) / 
		COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM
	 website_sessions
LEFT JOIN
	 orders
	 ON orders.website_session_id = website_sessions.website_session_id
WHERE
	 website_sessions.created_at BETWEEN '2012-08-22' AND '2012-09-18'
	 AND utm_campaign = 'nonbrand'
GROUP BY
	 1, 2;

-- The campaigns don't perform the same, gsearch outperforms bsearch on both mobile and desktop 
-- Recommend Marketing Director to bid down on bsearch based on its underperformance


/* Assignment 3.4 : Analyzing Channel Portfolio Trends. Based on previous analysis, Marketing bid down 
on bsearch nonbrand on December 2nd. Pull weekly session volume for gsearch and bsearch nonbrand, 
broken down by device, since November 4. Include a comparison metric to show bsearch as a percent of gsearch for each device. */

SELECT
	 MIN(DATE(created_at)) AS week_start_date,
	 COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
	 COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
	 COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS b_pct_of_g_dtop,
	 COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS g_mob_sessions,
	 COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS b_mob_sessions,
	 COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS b_pct_of_d_mob
FROM
	 website_sessions
WHERE
	 created_at BETWEEN '2012-11-4' AND '2012-12-22'
GROUP BY 
	 YEARWEEK(created_at);

-- bsearch traffic was slightly down 
-- gsearch dropped too after Black Friday and Cyber Monday but less compared to bsearch; this is alright given the low conversion rate


/* Assignment 3.5 : Analyzing Direct Traffic. A potential investor is curious whether any brand momentum 
is being built or will the company keep relying on paid traffic. Pull organic search, direct type in, 
and paid brand search sessions by month, and show those sessions as a percentage of paid search nonbrand. */

SELECT
	 YEAR(created_at) AS yr,
	 MONTH(created_at) AS mo,
	 COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand_sessions,
	 COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS brand_sessions,
	 COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand,
	 COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct_type_in,
	 COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
	 COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organic,
	 COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM
	 website_sessions
WHERE 
	 created_at <= '2012-12-23'
GROUP BY
	 1, 2;

-- brand, direct, and organic volumes are increasing and also growing as a percentage of paid traffic volume


------------------------------------------ SECTION FOUR : ANALYZING BUSINESS PATTERNS AND SEASONALITY --------------------------------------------------

/* Assignment 4.1 : Analyzing Seasonality. Look at 2012 monthly and weekly volume patterns to identify 
any seasonal trends to plan for 2013. Pull session volume and order volume. */

-- Note: Two separate queries are being requested

-- First, pull monthly session and order volume patterns
SELECT
	 YEAR(website_sessions.created_at) AS year,
	 MONTH(website_sessions.created_at) AS month,
	 COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	 COUNT(DISTINCT orders.order_id) AS orders
FROM 
	 website_sessions
LEFT JOIN 
	 orders
	 ON orders.website_session_id = website_sessions.website_session_id
WHERE 
	 website_sessions.created_at < '2013-01-01'
GROUP BY
	1, 2;

-- Second, pull weekly session and order volume patterns
SELECT
	 MIN(DATE(website_sessions.created_at)) AS week_start_date,
	 COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	 COUNT(DISTINCT orders.order_id) AS orders
FROM 
	 website_sessions
LEFT JOIN 
	 orders
	 ON orders.website_session_id = website_sessions.website_session_id
WHERE 
	 website_sessions.created_at < '2013-01-01'
GROUP BY
	 YEARWEEK(website_sessions.created_at);

-- Business grew steadily all year, significant volume in the holiday months, especially Black Friday and Cyber Monday weeks
-- Think about planning ahead in terms of customer support and inventory management during these periods this 2013


/* Assignment 4.2 : Analyzing Business Patterns. In considering the decision to add live chat support to 
improve customer experience, analyze the average website session volume, by hour of fay and by day week, 
to staff appropriately. Date range: September 15 -Nov 15, 2012 to avoid the holiday time period. */

SELECT
	 hr,
	 ROUND(AVG(DISTINCT CASE WHEN wkday = 0 THEN website_sessions ELSE NULL END), 1) AS mon,
	 ROUND(AVG(DISTINCT CASE WHEN wkday = 1 THEN website_sessions ELSE NULL END), 1) AS tue,
	 ROUND(AVG(DISTINCT CASE WHEN wkday = 2 THEN website_sessions ELSE NULL END), 1) AS wed,
	 ROUND(AVG(DISTINCT CASE WHEN wkday = 3 THEN website_sessions ELSE NULL END), 1) AS thu,
	 ROUND(AVG(DISTINCT CASE WHEN wkday = 4 THEN website_sessions ELSE NULL END), 1) AS fri,
	 ROUND(AVG(DISTINCT CASE WHEN wkday = 5 THEN website_sessions ELSE NULL END), 1) AS sat,
	 ROUND(AVG(DISTINCT CASE WHEN wkday = 6 THEN website_sessions ELSE NULL END), 1) AS sun
FROM (
	SELECT
		 DATE(created_at) AS created_date,
		 WEEKDAY(created_at) AS wkday,
		 HOUR(created_at) AS hr,
		 COUNT(DISTINCT website_session_id) AS website_sessions
	FROM 
		 website_sessions
	WHERE 
		 created_at BETWEEN '2012-09-15' AND '2012-11-15'
	GROUP BY
		 1, 2, 3
) AS granular_date_sessions

GROUP BY 1;

/* Looks like we can plan one support staff around the clock but double that to two support staff from 8AM to 5PM from Monday through Friday,
based on a division of labor of 10 sessions per hour per staff support employee */


------------------------------------------ SECTION SIX : USER ANALYSIS --------------------------------------------------

/* Assignment 6.1 : Identifying Repeat Beheaviors. Received: 2014-11-01
Marketing Director: Pull data on the number of website visitors that come back for another session, 2014 to date. */

-- first, gather the relevant user and session ids
CREATE TEMPORARY TABLE sessions_w_repeats
SELECT
	 first_sessions.user_id,
	 first_sessions.website_session_id AS first_session_id,
	 website_sessions.website_session_id AS repeat_session_id
FROM (
	SELECT
		 user_id,
		 website_session_id
	FROM 
		 website_sessions
	WHERE 
		 created_at BETWEEN '2014-01-01' AND '2014-11-01'
		 AND is_repeat_session = 0
) AS first_sessions
LEFT JOIN 
	 website_sessions
	 ON website_sessions.user_id = first_sessions.user_id
	 AND website_sessions.is_repeat_session = 1
	 AND website_sessions.website_session_id > first_sessions.website_session_id
	 AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-01';
-- end of temp table

-- summarize the data, grouped by repeat sessions
SELECT
	 repeat_sessions,
	 COUNT(DISTINCT user_id) AS users
FROM (
	SELECT
		 user_id,
		 COUNT(DISTINCT first_session_id) AS first_sessions,
		 COUNT(DISTINCT repeat_session_id) AS repeat_sessions
	FROM 
		 sessions_w_repeats
	GROUP BY 1
) AS user_lvl

GROUP BY 1;

RESULT:

repeat_sessions		users
0			126813
1			14086
2			315
3			4686

-- Looks like a fair number of customers do come back to the website after their first session


/* Assignment 6.2 : Analyzing Time to Repeat. Received: 2014-11-03
Marketing Director: Pull the minimum, maximum, and average time between the first 
and second sesson for repeat customers, from 2014 to date. */

-- gather the relevant sessions with dates
CREATE TEMPORARY TABLE sessions_repeats_w_dates
SELECT
	 first_sessions.user_id,
	 first_sessions.website_session_id AS first_session_id,
	 first_sessions.created_at AS first_session_date,
	 website_sessions.website_session_id AS repeat_session_id,
	 website_sessions.created_at AS repeat_session_date
FROM (
	SELECT
		 user_id,
		 created_at,
		 website_session_id
	FROM 
		 website_sessions
	WHERE 
		 created_at BETWEEN '2014-01-01' AND '2014-11-03'
	AND 
		 is_repeat_session = 0
) AS first_sessions
LEFT JOIN 
	 website_sessions
	 ON website_sessions.user_id = first_sessions.user_id
	 AND website_sessions.is_repeat_session = 1
	 AND website_sessions.website_session_id > first_sessions.website_session_id
	 AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-03';
-- end of temp table

-- gather the difference between first date and repeat date per user id
CREATE TEMPORARY TABLE user_level_repeat_date_diff
SELECT
	 user_id,
	 DATEDIFF(min_repeat_session_date, first_session_date) AS date_diff_repeat
FROM (
	SELECT
		 user_id,
		 first_session_id,
		 first_session_date,
		 MIN(repeat_session_id) AS min_repeat_session_id,
		 MIN(repeat_session_date) AS min_repeat_session_date
	FROM 
		 sessions_repeats_w_dates
	GROUP BY 
		 1, 2, 3
) AS first_second_sessions;
-- end of temp table

-- aggregate the needed data from the previous tables
SELECT
	 AVG(date_diff_repeat) AS avg_days_before_repeat,
	 MIN(date_diff_repeat) AS min_days_before_repeat,
	 MAX(date_diff_repeat) AS max_days_before_repeat
FROM 
	 user_level_repeat_date_diff;

RESULT:

avg_days_before_repeat	min_days_before_repeat	max_days_before_repeat
33.2622			1			69

-- Looks like it takes a month on average for customers to revisit the website
-- Might be good to investigate the channels these users are using


/* Assignment 6.3 : Analyzing Repeat Channel Behavior. Compare new vs. repeat sessions by channel, from 2014 to date. */

SELECT
	 -- utm_source,
	 -- utm_campaign,
	 -- http_referer,
	 CASE
	 	WHEN utm_campaign IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        	WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
        	WHEN utm_campaign = 'brand' THEN 'paid_brand'
        	WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        	WHEN utm_source = 'socialbook' THEN 'paid_social'
        	ELSE 'check logic'
	 END AS channel_group,
	 COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS first_sessions,
	 COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM 
	 website_sessions
WHERE 
	 created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY 1
ORDER BY 3 DESC;

-- Most repeat sessions emanate from organic search, paid brand, and direct-type-in channels
-- Approximately only 1/3 come from a paid channel, so company is not paying much for these visits


/* Assignment 6.4 : Analyzing New and Repeat Conversion Rates. Received: 2014-11-08
Website Manager: Compare conversion rates and revenue per session for repeat sessions vs new sessions, from 2014 to date. */

SELECT
	 website_sessions.is_repeat_session,
	 COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	 -- COUNT(DISTINCT orders.order_id) AS orders,
	 COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
	 SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS rev_per_session
FROM 
	 website_sessions
LEFT JOIN 
	 orders
	 ON orders.website_session_id = website_sessions.website_session_id
WHERE 
	 website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-08'
GROUP BY 1;

RESULT:

is_repeat_session	sessions	conv_rate	rev_per_session
0			149787		0.0680		4.343754
1			33577		0.0811		5.168828

-- Conversion rate and revenue per session are both higher for repeat sessions
