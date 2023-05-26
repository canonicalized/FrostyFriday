USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

-- Create the cart_table table
CREATE OR REPLACE TABLE WEEK46_CART (
  cart_number INT,
  contents ARRAY
);

INSERT INTO WEEK46_CART (cart_number, contents)
    SELECT
            1 AS cart_number,
            ARRAY_CONSTRUCT(5, 10, 15, 20) AS contents
        UNION ALL
    SELECT
            2 AS cart_number,
            ARRAY_CONSTRUCT(8, 9, 10, 11, 12, 13, 14) AS contents;

SELECT * FROM WEEK46_CART;


CREATE OR REPLACE TABLE WEEK46_CART_REMOVAL (
  cart_number INT,
  content_to_remove INT,
  order_to_remove_in INT
);

INSERT INTO WEEK46_CART_REMOVAL (cart_number, content_to_remove, order_to_remove_in)
VALUES
  (1, 10, 1),
  (1, 15, 2),
  (1, 5, 3),
  (1, 20, 4),
  (2, 8, 1),
  (2, 14, 2),
  (2, 11, 3),
  (2, 12, 4),
  (2, 9, 5),
  (2, 10, 6),
  (2, 13, 7);

SELECT * FROM WEEK46_CART_REMOVAL;



WITH RECURSIVE unpack_cart AS (
  SELECT
    cr.cart_number,
    ct.contents AS current_contents_of_cart,
    cr.content_to_remove,
    cr.order_to_remove_in,
    1 AS iteration
  FROM WEEK46_CART ct
  JOIN WEEK46_CART_REMOVAL cr ON ct.cart_number = cr.cart_number
  WHERE cr.order_to_remove_in = 1

  UNION ALL

  SELECT
    uc.cart_number,
    ARRAY_REMOVE(uc.current_contents_of_cart, uc.content_to_remove),
    cr.content_to_remove,
    cr.order_to_remove_in,
    uc.iteration + 1
  FROM unpack_cart uc
  JOIN WEEK46_CART_REMOVAL cr ON uc.cart_number = cr.cart_number
  WHERE uc.iteration + 1 = cr.order_to_remove_in
)
SELECT
  cart_number,
  current_contents_of_cart,
  content_last_removed
FROM (
  SELECT
    cart_number,
    current_contents_of_cart,
    content_to_remove AS content_last_removed,
    ROW_NUMBER() OVER (PARTITION BY cart_number ORDER BY order_to_remove_in DESC) AS rn
  FROM unpack_cart
)
WHERE rn = 1;
