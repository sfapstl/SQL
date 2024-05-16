# E-commerce and Website Analytics Business Intelligence Project on MySQL Workbench

In this project, I will be roleplaying as a newly hired Database Analyst for Maven Fuzzy Factory, an eCommerce start-up, and will be working directly with the CEO, Marketing Director and Website Manager to help grow the business and analyze performance along the way 

**Business Concepts**: *Traffic Source Analysis, Landing Page Performance & Testing, Channel Portfolio Optimization, Product Level Website Analysis, Analyze Repeat Behavior*  

## The Database
The database has 6 tables representing data from March 2012 – May 2015 

	order_item_refunds 

	order_items 

	orders 

	products 

	website_pageviews 

	website_sessions 

The database schema can be viewed through this photo link : https://ibb.co/TtcLGym

## Business Problem

On September 25, customers were given the option to add a second product while on the /cart page. Compare the month before vs. the month after the change. Show clickthrough rate from the /cart page, average products per order, average order value, and overall revenue per /cart pageview.

Gathering the sessions on the /cart page:
```mysql
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
```

Gathering sessions viewing pages after /cart
```mysql
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
```

Gathering the sessions on /cart that converted to orders:
```mysql
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
```

Finally, summarizing the data grouped by time period:
```mysql
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
```

Running the final query, we get this result:

| time_period       | cart_sessions | clickthroughs | cart_ctr | products_per_order | avg_order_value | rev_per_cart_session |
|-------------------|---------------|---------------|----------|--------------------|-----------------|----------------------|
| A. Pre_Cross_Sell | 1830          | 1229          | 0.6716   | 1.0000             | 51.4164         | 18.3188              |
| B. Post_Cross_Sell| 1975          | 1351          | 0.6841   | 1.0447             | 54.2518         | 18.4319              |

- It looks like clickthrough rates from the /cart page did not go down, and products per order, average order value, and revenue per /cart session are all up since the addition of cross-selling.
- Adding the cross-sell feature on te /cart page might be good for business, explore the feature further






