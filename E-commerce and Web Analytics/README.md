# E-commerce and Website Analytics Business Intelligence Project on MySQL Workbench

In this project, I will be roleplaying as a newly hired Database Analyst for Maven Fuzzy Factory, an eCommerce start-up, and will be working directly with the CEO, Marketing Director and Website Manager to help grow the business and analyze performance along the way. 

**Business Concepts**: Traffic Source Analysis | Landing Page Performance & Testing | Channel Portfolio Optimization | Product Level Website Analysis | Analyze Repeat Behavior

## The Database

The database has 6 tables representing data from March 2012 – May 2015 

	order_item_refunds 

	order_items 

	orders 

	products 

	website_pageviews 

	website_sessions 

Complete overview of the database schema:

![The Maven Fuzzy Factory database schema](https://i.ibb.co/NKxSqRZ/mavenfuzzyfactory-db-schema.png)

## Website Analytics

The entire code for SQL Project is available in [E-commerce and Website Analytics Project](https://github.com/sfapstl/SQL/blob/main/E-commerce%20and%20Web%20Analytics/E-commerce%20and%20Web%20Analytics%20Project.sql). 

Below are code extracts from each of the five sections for perusal.

### Product Analysis

**Cross-sell Analysis**. On September 25, customers were given the option to add a second product while on the `/cart` page. Compare the month before vs. the month after the change. Show clickthrough rate from the `/cart` page, average products per order, average order value, and overall revenue per `/cart` pageview.

Gathering the sessions on the `/cart` page.
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

Gathering sessions viewing pages after `/cart`.
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

Gathering the sessions on `/cart` that converted to orders.
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

Finally, summarizing the data grouped by time period.
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

- It looks like clickthrough rates from the `/cart` page did not go down, and products per order, average order value, and revenue per `/cart` session are all up since the addition of cross-selling
- Adding the cross-sell feature on the `/cart` page might be good for business, useful to explore the feature further


### Traffic Source Analysis

**Bid Optimization for Paid Traffic**. Investigate conversion rates from sessions to orders by device type (desktop or mobile) to determine whether we need to bid up on either.

```mysql
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
```

| device_type | sessions | orders | session_to_order_conv_rate |
|-------------|----------|--------|----------------------------|
| desktop     | 3911     | 146    | 0.0373                     |
| mobile      | 2492     | 24     | 0.0096                     |

- Desktop sessions have 3.7% conversion rate versus mobile at only 1%
- Recommend an increase to bids on desktop to rank higher in auctions and lead to sales boosts


### Analyzing Website Performance

**Building Conversion Funnels**. The Website Manager wants to understand where we lose gsearch visitors between /lander-1 and placing an order. Build a full conversion funnel, analyzing how many customers make it to each step. Start with /lander-1 to the thank you page. Use data since August 5 to September 5, 2012.

First, gather the relevant sessions and track pageviews visited using CASE WHEN and use this query as a subquery. Second, create a temporary table showing the conversion funnel per website session using the subquery.
```mysql
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
```

Third, calculate the click through rates from the temporary table.
```mysql
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
```

| lander_click_rt | products_click_rt | mrfuzzy_click_rt | cart_click_rt | shipping_click_rt | billing_click_rt |
|-----------------|-------------------|------------------|---------------|-------------------|------------------|
| 0.4707          | 0.7409            | 0.4359           | 0.6662        | 0.7934            | 0.4377           |

Based on this analysis, I would recommend the Website Manager to focus on the lander, Mr. Fuzzy page, and the billing page which have the lowest click rates.


### Analysis for Channel Portfolio Management

**Analyzing Direct Traffic**. A potential investor is curious whether any brand momentum is being built or will the company keep relying on paid traffic. Pull organic search, direct type in, and paid brand search sessions by month, and show those sessions as a percentage of paid search nonbrand.

```mysql
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
```

| yr  | mo | nonbrand_sessions | brand_sessions | brand_pct_of_nonbrand | direct_type_in | direct_pct_of_nonbrand | organic | organic_pct_of_nonbrand |
|-----|----|-------------------|----------------|-----------------------|----------------|------------------------|---------|-------------------------|
| 2012| 3  | 1852              | 10             | 0.0054                | 9              | 0.0049                 | 8       | 0.0043                  |
| 2012| 4  | 3509              | 76             | 0.0217                | 71             | 0.0202                 | 78      | 0.0222                  |
| 2012| 5  | 3295              | 140            | 0.0425                | 151            | 0.0458                 | 150     | 0.0455                  |
| 2012| 6  | 3439              | 164            | 0.0477                | 170            | 0.0494                 | 190     | 0.0552                  |
| 2012| 7  | 3660              | 195            | 0.0533                | 187            | 0.0511                 | 207     | 0.0566                  |
| 2012| 8  | 5318              | 264            | 0.0496                | 250            | 0.0470                 | 265     | 0.0498                  |
| 2012| 9  | 5591              | 339            | 0.0606                | 285            | 0.0510                 | 331     | 0.0592                  |
| 2012| 10 | 6883              | 432            | 0.0628                | 440            | 0.0639                 | 428     | 0.0622                  |
| 2012| 11 | 12260             | 556            | 0.0454                | 571            | 0.0466                 | 624     | 0.0509                  |
| 2012| 12 | 6643              | 464            | 0.0698                | 482            | 0.0726                 | 492     | 0.0741                  |

Brand, direct, and organic volumes are increasing and also growing as a percentage of paid traffic volume.

### Analyzing Business Patterns and Seasonality

**Analyzing Time to Repeat**. Marketing Director: Pull the minimum, maximum, and average time between the first and second sesson for repeat customers, from 2014 to date.

Gather the relevant sessions with dates.
```mysql
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
```

Gather the difference between first date and repeat date per user id.
```mysql
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
```

Aggregate the needed data from the previous tables.
```mysql
SELECT
	 AVG(date_diff_repeat) AS avg_days_before_repeat,
	 MIN(date_diff_repeat) AS min_days_before_repeat,
	 MAX(date_diff_repeat) AS max_days_before_repeat
FROM 
	 user_level_repeat_date_diff;
```

| avg_days_before_repeat | min_days_before_repeat | max_days_before_repeat |
|------------------------|------------------------|------------------------|
| 33.2622                | 1                      | 69                     |

- Looks like it takes a month on average for customers to revisit the website
- Might be good to investigate the channels these users are using







