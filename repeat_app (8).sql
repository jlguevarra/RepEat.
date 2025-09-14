-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 14, 2025 at 07:07 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `repeat_app`
--

-- --------------------------------------------------------

--
-- Table structure for table `camera_workouts`
--

CREATE TABLE `camera_workouts` (
  `workout_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `category` varchar(50) NOT NULL,
  `exercise_name` varchar(100) NOT NULL,
  `detected_reps` int(11) NOT NULL,
  `duration_seconds` int(11) DEFAULT 0,
  `accuracy_score` float DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `camera_workouts`
--

INSERT INTO `camera_workouts` (`workout_id`, `user_id`, `date`, `category`, `exercise_name`, `detected_reps`, `duration_seconds`, `accuracy_score`, `created_at`) VALUES
(2, 4, '2025-07-17', 'Upper Body', 'Push-ups', 0, 0, 0, '2025-07-17 02:01:09'),
(3, 4, '2025-07-18', 'Cardio', 'Burpees', 0, 0, 0, '2025-07-18 02:11:56'),
(4, 4, '2025-07-19', 'Upper Body', 'Shoulder Press', 0, 49, 0, '2025-07-19 02:27:19'),
(5, 4, '2025-07-19', 'Upper Body', 'Shoulder Press', 0, 122, 0, '2025-07-19 02:28:32'),
(6, 4, '2025-07-19', 'Core', 'Sit-ups', 2, 52, 0, '2025-07-19 02:31:13'),
(7, 4, '2025-07-19', 'Upper Body', 'Push-ups', 2, 80, 54.9735, '2025-07-19 02:38:54'),
(8, 4, '2025-07-19', 'Upper Body', 'Push-ups', 7, 125, 0.66, '2025-07-19 02:57:41'),
(9, 4, '2025-07-19', 'Upper Body', 'Push-ups', 1, 18, 0.48, '2025-07-19 03:06:14'),
(10, 4, '2025-07-22', 'Biceps', 'Dumbbell Curls', 0, 0, 0, '2025-07-22 02:44:21'),
(11, 4, '2025-07-22', 'Biceps', 'Dumbbell Curls', 5, 0, 0, '2025-07-22 02:44:32'),
(12, 4, '2025-07-23', 'Biceps', 'Dumbbell Curls', 0, 0, 0, '2025-07-23 10:37:35'),
(13, 4, '2025-07-23', 'Biceps', 'Hammer Curls', 3, 0, 0, '2025-07-23 10:37:47'),
(14, 4, '2025-07-24', 'Biceps', 'Hammer Curls', 0, 0, 0, '2025-07-24 02:16:50'),
(15, 4, '2025-07-24', 'Biceps', 'Hammer Curls', 0, 0, 0, '2025-07-24 02:16:51'),
(16, 4, '2025-09-05', 'Arms', 'Vertical Swing (dumbbell)', 1, 97, 0, '2025-09-05 00:32:50');

-- --------------------------------------------------------

--
-- Table structure for table `email_verifications`
--

CREATE TABLE `email_verifications` (
  `id` int(11) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `code` varchar(6) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `email_verifications`
--

INSERT INTO `email_verifications` (`id`, `email`, `code`, `created_at`) VALUES
(28, 'deramosmichael27@gmail.com', '969745', '2025-08-25 13:47:03'),
(33, 'johnloydguevarra0405@gmail.com', '728850', '2025-09-06 16:14:29'),
(37, 'johnlloydguevarra0405@gmail.com', '134662', '2025-09-08 10:22:03'),
(38, 'johnlloydguevarra2@gmail.com', '546965', '2025-09-08 13:24:55');

-- --------------------------------------------------------

--
-- Table structure for table `favorites`
--

CREATE TABLE `favorites` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `recipe_id` int(11) NOT NULL,
  `recipe_title` varchar(255) NOT NULL,
  `recipe_image` varchar(500) DEFAULT NULL,
  `saved_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `meal_plans`
--

CREATE TABLE `meal_plans` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `time_frame` enum('day','week') NOT NULL,
  `start_date` date DEFAULT NULL,
  `meal_plan` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `meal_plans`
--

INSERT INTO `meal_plans` (`id`, `user_id`, `time_frame`, `start_date`, `meal_plan`, `created_at`, `updated_at`) VALUES
(4, 6, 'day', NULL, '{\"meals\":[{\"id\":636026,\"image\":\"Breakfast-Biscuits-and-Gravy-636026.jpg\",\"imageType\":\"jpg\",\"title\":\"Breakfast Biscuits and Gravy\",\"readyInMinutes\":45,\"servings\":4,\"sourceUrl\":\"http://www.foodista.com/recipe/S8F5B5H4/breakfast-biscuits-and-gravy\"},{\"id\":991010,\"image\":\"chicken-ranch-burgers-991010.jpg\",\"imageType\":\"jpg\",\"title\":\"Chicken Ranch Burgers\",\"readyInMinutes\":25,\"servings\":3,\"sourceUrl\":\"https://www.pinkwhen.com/chicken-ranch-burgers-recipe/\"},{\"id\":650487,\"image\":\"Lusciously-Lemony-Lentil-Soup-650487.jpg\",\"imageType\":\"jpg\",\"title\":\"Lusciously Lemony Lentil Soup\",\"readyInMinutes\":45,\"servings\":1,\"sourceUrl\":\"https://www.foodista.com/recipe/RFKZ88M8/lusciously-lemony-lentil-soup\"}],\"nutrients\":{\"calories\":2500.18,\"protein\":127.55,\"fat\":169.51,\"carbohydrates\":113.75}}', '2025-07-30 06:59:10', '2025-07-30 07:03:35'),
(5, 9, 'day', NULL, '{\"meals\":[{\"id\":1100990,\"image\":\"blueberry-chocolate-cocao-superfood-pancakes-gluten-free-paleo-vegan-1100990.jpg\",\"imageType\":\"jpg\",\"title\":\"Blueberry, Chocolate & Cocao Superfood Pancakes - Gluten-Free/Paleo/Vegan\",\"readyInMinutes\":30,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/35NX6PZB/blueberry-chocolate-cocao-superfood-pancakes-gluten-free-paleo-vegan\"},{\"id\":642681,\"image\":\"Fesenjan-642681.jpg\",\"imageType\":\"jpg\",\"title\":\"Fesenjan Chicken Stew\",\"readyInMinutes\":30,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/KRVYLC3H/fesenjan\"},{\"id\":661055,\"image\":\"Spicy-Chili-w-Boneless-Beef-Short-Ribs-661055.jpg\",\"imageType\":\"jpg\",\"title\":\"Spicy Chili w Boneless Beef Short Ribs\",\"readyInMinutes\":45,\"servings\":6,\"sourceUrl\":\"http://www.foodista.com/recipe/Y4HNTZ6S/spicy-chili-w-boneless-beef-short-ribs\"}],\"nutrients\":{\"calories\":2491.53,\"protein\":138.03,\"fat\":151.77,\"carbohydrates\":153.59}}', '2025-08-13 07:15:46', '2025-08-13 07:15:46'),
(6, 13, 'day', NULL, '{\"meals\":[{\"id\":1957598,\"image\":\"low-carb-keto-pancakes-1957598.jpg\",\"imageType\":\"jpg\",\"title\":\"Low Carb Keto Pancakes\",\"readyInMinutes\":15,\"servings\":2,\"sourceUrl\":\"https://spoonacular.com/site-1721579912124\"},{\"id\":643634,\"image\":\"Fresh-Tomatoes-With-Beans-and-Macaroni-643634.jpg\",\"imageType\":\"jpg\",\"title\":\"Macaroni with Fresh Tomatoes and Beans\",\"readyInMinutes\":25,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/LY45JTQD/fresh-tomatoes-with-beans-and-macaroni\"},{\"id\":636256,\"image\":\"Broiled-Crab-Cakes-636256.jpg\",\"imageType\":\"jpg\",\"title\":\"Broiled Crab Cakes\",\"readyInMinutes\":45,\"servings\":3,\"sourceUrl\":\"https://www.foodista.com/recipe/RBLXQMWS/broiled-crabcakes\"}],\"nutrients\":{\"calories\":1500.07,\"protein\":76.73,\"fat\":75.83,\"carbohydrates\":133.98}}', '2025-08-18 06:23:44', '2025-08-18 06:23:44'),
(7, 4, 'day', NULL, '{\"meals\":[{\"id\":1697767,\"image\":\"the-perfect-scrambled-eggs-every-time-1697767.jpg\",\"imageType\":\"jpg\",\"title\":\"The Perfect Scrambled Eggs - Every Time\",\"readyInMinutes\":10,\"servings\":2,\"sourceUrl\":\"https://maplewoodroad.com/scrambled-eggs/\"},{\"id\":642593,\"image\":\"Farfalle-With-Sun-Dried-Tomato-Pesto--Sausage-and-Fennel-642593.jpg\",\"imageType\":\"jpg\",\"title\":\"Farfalle With Sun-Dried Tomato Pesto, Sausage and Fennel\",\"readyInMinutes\":20,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/CSLBDWBS/farfalle-with-sun-dried-tomato-pesto-sausage-and-fennel\"},{\"id\":640700,\"image\":\"Creamy-Shrimp-Bisque-640700.jpg\",\"imageType\":\"jpg\",\"title\":\"Creamy Shrimp Bisque\",\"readyInMinutes\":45,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/3FG3Z8PJ/creamy-shrimp-bisque\"}],\"nutrients\":{\"calories\":1499.95,\"protein\":75.28,\"fat\":71.83,\"carbohydrates\":138.53}}', '2025-09-05 03:22:37', '2025-09-05 03:22:37'),
(8, 19, 'day', NULL, '{\"meals\":[],\"nutrients\":{\"calories\":0.0,\"protein\":0.0,\"fat\":0.0,\"carbohydrates\":0.0}}', '2025-09-05 04:39:34', '2025-09-05 04:41:08'),
(9, 25, 'day', NULL, '{\"meals\":[{\"id\":1100990,\"image\":\"blueberry-chocolate-cocao-superfood-pancakes-gluten-free-paleo-vegan-1100990.jpg\",\"imageType\":\"jpg\",\"title\":\"Blueberry, Chocolate & Cocao Superfood Pancakes - Gluten-Free/Paleo/Vegan\",\"readyInMinutes\":30,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/35NX6PZB/blueberry-chocolate-cocao-superfood-pancakes-gluten-free-paleo-vegan\"},{\"id\":637908,\"image\":\"Chicken-and-Miso-Ramen-Noodle-Soup-637908.jpg\",\"imageType\":\"jpg\",\"title\":\"Chicken and Miso Ramen Noodle Soup\",\"readyInMinutes\":30,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/LSGT2GRK/chicken-and-miso-ramen-noodle-soup\"},{\"id\":640869,\"image\":\"Crock-Pot-Shredded-French-Dip-640869.jpg\",\"imageType\":\"jpg\",\"title\":\"Crock Pot Shredded French Dip\",\"readyInMinutes\":450,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/JZSG6DMV/crock-pot-shredded-french-dip\"}],\"nutrients\":{\"calories\":2495.79,\"protein\":156.15,\"fat\":113.81,\"carbohydrates\":216.52}}', '2025-09-05 04:52:43', '2025-09-05 04:52:43'),
(10, 26, 'day', NULL, '{\"meals\":[{\"id\":1100990,\"image\":\"blueberry-chocolate-cocao-superfood-pancakes-gluten-free-paleo-vegan-1100990.jpg\",\"imageType\":\"jpg\",\"title\":\"Blueberry, Chocolate & Cocao Superfood Pancakes - Gluten-Free/Paleo/Vegan\",\"readyInMinutes\":30,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/35NX6PZB/blueberry-chocolate-cocao-superfood-pancakes-gluten-free-paleo-vegan\"},{\"id\":1697577,\"image\":\"spanish-sardines-pasta-1697577.jpg\",\"imageType\":\"jpg\",\"title\":\"Spanish Sardines Pasta\",\"readyInMinutes\":25,\"servings\":2,\"sourceUrl\":\"https://maplewoodroad.com/spanish-sardines-pasta/\"},{\"id\":1697541,\"image\":\"pasta-with-feta-cheese-and-asparagus-1697541.jpg\",\"imageType\":\"jpg\",\"title\":\"Pasta With Feta Cheese And Asparagus\",\"readyInMinutes\":20,\"servings\":2,\"sourceUrl\":\"https://maplewoodroad.com/pasta-with-feta-cheese-and-asparagus/\"}],\"nutrients\":{\"calories\":2500.57,\"protein\":83.16,\"fat\":119.61,\"carbohydrates\":282.0}}', '2025-09-06 06:25:12', '2025-09-06 06:25:12'),
(11, 29, 'day', NULL, '{\"meals\":[],\"nutrients\":{\"calories\":0.0,\"protein\":0.0,\"fat\":0.0,\"carbohydrates\":0.0}}', '2025-09-08 01:11:00', '2025-09-08 01:11:05'),
(12, 30, 'day', NULL, '{\"meals\":[{\"id\":634882,\"image\":\"Best-Breakfast-Burrito-634882.jpg\",\"imageType\":\"jpg\",\"title\":\"Best Breakfast Burrito\",\"readyInMinutes\":45,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/WLQNMQ5B/best-breakfast-burrito\"},{\"id\":637908,\"image\":\"Chicken-and-Miso-Ramen-Noodle-Soup-637908.jpg\",\"imageType\":\"jpg\",\"title\":\"Chicken and Miso Ramen Noodle Soup\",\"readyInMinutes\":30,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/LSGT2GRK/chicken-and-miso-ramen-noodle-soup\"},{\"id\":654568,\"image\":\"Panned-Veal-Chop-654568.jpg\",\"imageType\":\"jpg\",\"title\":\"Panned Veal Chop\",\"readyInMinutes\":45,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/J8GR258F/panned-veal-chop\"}],\"nutrients\":{\"calories\":2500.0,\"protein\":134.32,\"fat\":104.46,\"carbohydrates\":250.38}}', '2025-09-08 01:16:28', '2025-09-08 01:16:28'),
(13, 31, 'day', NULL, '{\"meals\":[{\"id\":634882,\"image\":\"Best-Breakfast-Burrito-634882.jpg\",\"imageType\":\"jpg\",\"title\":\"Best Breakfast Burrito\",\"readyInMinutes\":45,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/WLQNMQ5B/best-breakfast-burrito\"},{\"id\":650377,\"image\":\"Low-Carb-Brunch-Burger-650377.jpg\",\"imageType\":\"jpg\",\"title\":\"Low Carb Brunch Burger\",\"readyInMinutes\":30,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/5SPTY657/low-carb-brunch-burger\"},{\"id\":654953,\"image\":\"Pasta-with-Spicy-Sausage---Rapini-654953.jpg\",\"imageType\":\"jpg\",\"title\":\"Pasta with Spicy Sausage & Rapini\",\"readyInMinutes\":45,\"servings\":8,\"sourceUrl\":\"https://www.foodista.com/recipe/T552585W/pasta-with-spicy-sausage-rapini\"}],\"nutrients\":{\"calories\":2498.82,\"protein\":107.26,\"fat\":162.92,\"carbohydrates\":152.39}}', '2025-09-08 01:45:50', '2025-09-08 01:45:50'),
(14, 32, 'day', NULL, '{\"meals\":[{\"id\":636026,\"image\":\"Breakfast-Biscuits-and-Gravy-636026.jpg\",\"imageType\":\"jpg\",\"title\":\"Breakfast Biscuits and Gravy\",\"readyInMinutes\":45,\"servings\":4,\"sourceUrl\":\"http://www.foodista.com/recipe/S8F5B5H4/breakfast-biscuits-and-gravy\"},{\"id\":650127,\"image\":\"Linguine-in-Cream-Sauce-with-Poached-Eggs-and-Bacon-650127.jpg\",\"imageType\":\"jpg\",\"title\":\"Linguine in Cream Sauce with Poached Eggs and Bacon\",\"readyInMinutes\":25,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/YQQZ6X46/linguine-in-cream-sauce-with-poached-eggs-and-bacon\"},{\"id\":642281,\"image\":\"Eggplant-Caprese-Stacks-642281.jpg\",\"imageType\":\"jpg\",\"title\":\"Eggplant Caprese Stack Appetizers\",\"readyInMinutes\":30,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/V4KYVH2L/eggplant-caprese-stacks\"}],\"nutrients\":{\"calories\":2501.2,\"protein\":89.02,\"fat\":166.86,\"carbohydrates\":162.51}}', '2025-09-08 03:28:57', '2025-09-08 03:54:59'),
(15, 33, 'day', NULL, '{\"meals\":[{\"id\":636026,\"image\":\"Breakfast-Biscuits-and-Gravy-636026.jpg\",\"imageType\":\"jpg\",\"title\":\"Breakfast Biscuits and Gravy\",\"readyInMinutes\":45,\"servings\":4,\"sourceUrl\":\"http://www.foodista.com/recipe/S8F5B5H4/breakfast-biscuits-and-gravy\"},{\"id\":643634,\"image\":\"Fresh-Tomatoes-With-Beans-and-Macaroni-643634.jpg\",\"imageType\":\"jpg\",\"title\":\"Macaroni with Fresh Tomatoes and Beans\",\"readyInMinutes\":25,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/LY45JTQD/fresh-tomatoes-with-beans-and-macaroni\"},{\"id\":650484,\"image\":\"Luscious-Palak-Paneer-650484.jpg\",\"imageType\":\"jpg\",\"title\":\"Luscious Palak Paneer\",\"readyInMinutes\":30,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/WKQQKG5K/luscious-palak-paneer\"}],\"nutrients\":{\"calories\":2496.83,\"protein\":96.95,\"fat\":150.3,\"carbohydrates\":195.6}}', '2025-09-08 06:21:39', '2025-09-08 06:21:39');

-- --------------------------------------------------------

--
-- Table structure for table `onboarding_data`
--

CREATE TABLE `onboarding_data` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `body_type` varchar(50) DEFAULT NULL,
  `current_weight` varchar(10) DEFAULT NULL,
  `target_weight` varchar(10) DEFAULT NULL,
  `height` varchar(10) DEFAULT NULL,
  `goal` varchar(50) DEFAULT NULL,
  `has_injury` tinyint(1) DEFAULT NULL,
  `injury_details` varchar(100) DEFAULT NULL,
  `diet_preference` varchar(50) DEFAULT NULL,
  `allergies` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `onboarding_data`
--

INSERT INTO `onboarding_data` (`id`, `user_id`, `gender`, `birthdate`, `body_type`, `current_weight`, `target_weight`, `height`, `goal`, `has_injury`, `injury_details`, `diet_preference`, `allergies`, `created_at`) VALUES
(17, 4, 'Male', '2007-01-01', 'Overweight', '90', '80', '190', 'Weight Loss', 1, 'Knee Pain', 'Low-Carb', 'None', '2025-07-08 10:04:09'),
(35, 24, 'Male', '2007-08-25', 'Overweight', '95', '75', '190', 'Weight Loss', 0, 'None', 'Low Fat', 'None', '2025-08-25 05:48:31'),
(44, 32, 'Male', '2007-09-08', 'Normal', '70', '75', '175', 'Muscle Gain', 0, 'None', 'High Protein', 'Shellfish', '2025-09-08 02:22:49'),
(45, 33, 'Male', '2007-09-08', 'Normal', '70', '60', '175', 'Weight Loss', 0, 'None', 'High Protein', 'Shellfish', '2025-09-08 05:26:16');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `code` varchar(10) NOT NULL,
  `used` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `password_resets`
--

INSERT INTO `password_resets` (`id`, `email`, `code`, `used`, `created_at`) VALUES
(5, 'johnlloydguevarra2@gmail.com', '499286', 0, '2025-06-26 08:50:44'),
(6, 'johnlloydguevarra2@gmail.com', '858167', 1, '2025-06-30 09:30:16'),
(10, 'johnlloydguevarra2@gmail.com', '463755', 0, '2025-08-02 06:31:19'),
(12, 'johnlloydguevarra2@gmail.com', '281915', 0, '2025-08-02 09:37:42'),
(13, 'johnlloydguevarra2@gmail.com', '431456', 0, '2025-08-15 03:35:28'),
(14, 'johnlloydguevarra2@gmail.com', '695816', 0, '2025-08-15 03:36:51'),
(15, 'johnlloydguevarra2@gmail.com', '886541', 1, '2025-08-15 03:37:40'),
(17, 'johnlloydguevarra0405@gmail.com', '441553', 0, '2025-08-18 06:44:11');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_onboarded` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `email`, `password`, `name`, `created_at`, `is_onboarded`) VALUES
(3, 'sample1@gmail.com', '$2y$10$cfgwRBhztrlOzAOQD89kkel65R0vY0UpJRD5w8sfqRvEfZXHW/t3a', 'Sample', '2025-06-25 08:19:18', 0),
(4, 'user@example.com', '$2y$10$VIOGkFDh1sD8FXqMBkPrR.0/.1PTI4gur3MCymM39KJM2q2JPsUO2', 'John Doe', '2025-06-26 07:17:53', 1),
(24, 'deramosmichael27@gmail.com', '$2y$10$Ww/5s5yDXh9SI5nwz1.Ymu8/nRgaFoIMOD7FyjdFDPC2gEU6Rw6he', 'myke', '2025-08-25 05:47:33', 1),
(32, 'johnlloydguevarra0405@gmail.com', '$2y$10$WoKPmY78nKVIaClGqmoAw.p8juofLJBNxAS96A/PGEI5qTK0t5AYy', 'John Lloyd Guevarra', '2025-09-08 02:22:27', 1),
(33, 'johnlloydguevarra2@gmail.com', '$2y$10$OT4HaZJwoAFy07gBFmhereJ0SCS0E144Ig1kzE069EWVzOK6Prh8a', 'Juan Dela Cruz', '2025-09-08 05:25:12', 1);

-- --------------------------------------------------------

--
-- Table structure for table `user_workout_plans`
--

CREATE TABLE `user_workout_plans` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `goal` varchar(50) NOT NULL,
  `sets` int(11) NOT NULL,
  `reps` int(11) NOT NULL,
  `plan_data` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `current_week_index` int(11) DEFAULT 0,
  `current_day_index` int(11) DEFAULT 0,
  `completed_today` tinyint(1) DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_workout_plans`
--

INSERT INTO `user_workout_plans` (`id`, `user_id`, `goal`, `sets`, `reps`, `plan_data`, `created_at`, `updated_at`, `current_week_index`, `current_day_index`, `completed_today`, `last_updated`) VALUES
(9, 33, 'weight_loss', 3, 12, '{\"weekly_plan\":{\"Week 1\":{\"Monday\":[\"Dumbbell Pullover\",\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\",\"Dumbbell Bench Press\"],\"Tuesday\":[\"Dumbbell Rows\",\"Dumbbell Reverse Flyes\",\"Dumbbell Bicep Curls\",\"Dumbbell Shrugs\"],\"Wednesday\":[\"Dumbbell Calf Raises\",\"Dumbbell Step-ups\",\"Dumbbell Squats\",\"Dumbbell Lunges\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Windmills\",\"Dumbbell Side Bends\",\"Dumbbell Russian Twists\",\"Dumbbell Sit-ups\"],\"Saturday\":[\"Dumbbell Triceps Extension\",\"Dumbbell Pullover\",\"Dumbbell Shoulder Press\",\"Dumbbell Bench Press\"],\"Sunday\":[\"Rest Day\"]},\"Week 2\":{\"Monday\":[\"Dumbbell Bicep Curls\",\"Dumbbell Rows\",\"Dumbbell Reverse Flyes\",\"Dumbbell Hammer Curls\"],\"Tuesday\":[\"Dumbbell Deadlifts\",\"Dumbbell Calf Raises\",\"Dumbbell Step-ups\",\"Dumbbell Squats\"],\"Wednesday\":[\"Dumbbell Windmills\",\"Dumbbell Side Bends\",\"Dumbbell Wood Chops\",\"Dumbbell Sit-ups\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Bench Press\",\"Dumbbell Shoulder Press\",\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\"],\"Saturday\":[\"Dumbbell Reverse Flyes\",\"Dumbbell Shrugs\",\"Dumbbell Hammer Curls\",\"Dumbbell Rows\"],\"Sunday\":[\"Rest Day\"]},\"Week 3\":{\"Monday\":[\"Dumbbell Calf Raises\",\"Dumbbell Step-ups\",\"Dumbbell Squats\",\"Dumbbell Lunges\"],\"Tuesday\":[\"Dumbbell Russian Twists\",\"Dumbbell Wood Chops\",\"Dumbbell Sit-ups\",\"Dumbbell Windmills\"],\"Wednesday\":[\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\",\"Dumbbell Shoulder Press\",\"Dumbbell Pullover\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Shrugs\",\"Dumbbell Reverse Flyes\",\"Dumbbell Hammer Curls\",\"Dumbbell Bicep Curls\"],\"Saturday\":[\"Dumbbell Lunges\",\"Dumbbell Squats\",\"Dumbbell Step-ups\",\"Dumbbell Deadlifts\"],\"Sunday\":[\"Rest Day\"]},\"Week 4\":{\"Monday\":[\"Dumbbell Wood Chops\",\"Dumbbell Russian Twists\",\"Dumbbell Sit-ups\",\"Dumbbell Windmills\"],\"Tuesday\":[\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\",\"Dumbbell Pullover\",\"Dumbbell Shoulder Press\"],\"Wednesday\":[\"Dumbbell Hammer Curls\",\"Dumbbell Bicep Curls\",\"Dumbbell Reverse Flyes\",\"Dumbbell Shrugs\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Step-ups\",\"Dumbbell Deadlifts\",\"Dumbbell Lunges\",\"Dumbbell Squats\"],\"Saturday\":[\"Dumbbell Side Bends\",\"Dumbbell Windmills\",\"Dumbbell Russian Twists\",\"Dumbbell Wood Chops\"],\"Sunday\":[\"Rest Day\"]}},\"generated_at\":\"2025-09-08 09:45:04\"}', '2025-09-08 07:45:04', '2025-09-08 07:45:04', 0, 0, 0, '2025-09-14 01:45:01'),
(13, 32, 'muscle_gain', 4, 8, '{\"weekly_plan\":{\"Week 1\":{\"Monday\":[\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\",\"Dumbbell Bench Press\",\"Dumbbell Pullover\",\"Dumbbell Shoulder Press\"],\"Tuesday\":[\"Dumbbell Reverse Flyes\",\"Dumbbell Bicep Curls\",\"Dumbbell Hammer Curls\",\"Dumbbell Rows\",\"Dumbbell Shrugs\"],\"Wednesday\":[\"Dumbbell Step-ups\",\"Dumbbell Lunges\",\"Dumbbell Deadlifts\",\"Dumbbell Calf Raises\",\"Dumbbell Squats\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Wood Chops\",\"Dumbbell Russian Twists\",\"Dumbbell Windmills\",\"Dumbbell Sit-ups\",\"Dumbbell Side Bends\"],\"Saturday\":[\"Dumbbell Bench Press\",\"Dumbbell Shoulder Press\",\"Dumbbell Pullover\",\"Dumbbell Triceps Extension\",\"Dumbbell Flyes\"],\"Sunday\":[\"Dumbbell Reverse Flyes\",\"Dumbbell Rows\",\"Dumbbell Shrugs\",\"Dumbbell Hammer Curls\",\"Dumbbell Bicep Curls\"]},\"Week 2\":{\"Monday\":[\"Dumbbell Calf Raises\",\"Dumbbell Squats\",\"Dumbbell Deadlifts\",\"Dumbbell Step-ups\",\"Dumbbell Lunges\"],\"Tuesday\":[\"Dumbbell Side Bends\",\"Dumbbell Sit-ups\",\"Dumbbell Russian Twists\",\"Dumbbell Windmills\",\"Dumbbell Wood Chops\"],\"Wednesday\":[\"Dumbbell Pullover\",\"Dumbbell Bench Press\",\"Dumbbell Triceps Extension\",\"Dumbbell Flyes\",\"Dumbbell Shoulder Press\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Bicep Curls\",\"Dumbbell Hammer Curls\",\"Dumbbell Reverse Flyes\",\"Dumbbell Rows\",\"Dumbbell Shrugs\"],\"Saturday\":[\"Dumbbell Calf Raises\",\"Dumbbell Lunges\",\"Dumbbell Step-ups\",\"Dumbbell Squats\",\"Dumbbell Deadlifts\"],\"Sunday\":[\"Dumbbell Wood Chops\",\"Dumbbell Side Bends\",\"Dumbbell Sit-ups\",\"Dumbbell Windmills\",\"Dumbbell Russian Twists\"]},\"Week 3\":{\"Monday\":[\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\",\"Dumbbell Bench Press\",\"Dumbbell Shoulder Press\",\"Dumbbell Pullover\"],\"Tuesday\":[\"Dumbbell Shrugs\",\"Dumbbell Rows\",\"Dumbbell Bicep Curls\",\"Dumbbell Hammer Curls\",\"Dumbbell Reverse Flyes\"],\"Wednesday\":[\"Dumbbell Calf Raises\",\"Dumbbell Deadlifts\",\"Dumbbell Lunges\",\"Dumbbell Step-ups\",\"Dumbbell Squats\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Sit-ups\",\"Dumbbell Wood Chops\",\"Dumbbell Russian Twists\",\"Dumbbell Side Bends\",\"Dumbbell Windmills\"],\"Saturday\":[\"Dumbbell Bench Press\",\"Dumbbell Triceps Extension\",\"Dumbbell Shoulder Press\",\"Dumbbell Flyes\",\"Dumbbell Pullover\"],\"Sunday\":[\"Dumbbell Hammer Curls\",\"Dumbbell Rows\",\"Dumbbell Shrugs\",\"Dumbbell Reverse Flyes\",\"Dumbbell Bicep Curls\"]},\"Week 4\":{\"Monday\":[\"Dumbbell Deadlifts\",\"Dumbbell Step-ups\",\"Dumbbell Squats\",\"Dumbbell Calf Raises\",\"Dumbbell Lunges\"],\"Tuesday\":[\"Dumbbell Side Bends\",\"Dumbbell Sit-ups\",\"Dumbbell Wood Chops\",\"Dumbbell Windmills\",\"Dumbbell Russian Twists\"],\"Wednesday\":[\"Dumbbell Pullover\",\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\",\"Dumbbell Bench Press\",\"Dumbbell Shoulder Press\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Hammer Curls\",\"Dumbbell Reverse Flyes\",\"Dumbbell Bicep Curls\",\"Dumbbell Rows\",\"Dumbbell Shrugs\"],\"Saturday\":[\"Dumbbell Squats\",\"Dumbbell Lunges\",\"Dumbbell Deadlifts\",\"Dumbbell Step-ups\",\"Dumbbell Calf Raises\"],\"Sunday\":[\"Dumbbell Side Bends\",\"Dumbbell Sit-ups\",\"Dumbbell Wood Chops\",\"Dumbbell Russian Twists\",\"Dumbbell Windmills\"]}},\"generated_at\":\"2025-09-09 06:21:27\"}', '2025-09-09 04:21:27', '2025-09-09 04:21:27', 0, 0, 0, '2025-09-14 01:45:01'),
(15, 24, 'weight_loss', 3, 12, '{\"weekly_plan\":{\"Week 1\":{\"Monday\":[\"Dumbbell Pullover\",\"Dumbbell Bench Press\",\"Dumbbell Triceps Extension\",\"Dumbbell Flyes\"],\"Tuesday\":[\"Dumbbell Reverse Flyes\",\"Dumbbell Rows\",\"Dumbbell Shrugs\",\"Dumbbell Hammer Curls\"],\"Wednesday\":[\"Dumbbell Deadlifts\",\"Dumbbell Lunges\",\"Dumbbell Squats\",\"Dumbbell Step-ups\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Russian Twists\",\"Dumbbell Wood Chops\",\"Dumbbell Sit-ups\",\"Dumbbell Windmills\"],\"Saturday\":[\"Dumbbell Triceps Extension\",\"Dumbbell Bench Press\",\"Dumbbell Flyes\",\"Dumbbell Pullover\"],\"Sunday\":[\"Rest Day\"]},\"Week 2\":{\"Monday\":[\"Dumbbell Rows\",\"Dumbbell Hammer Curls\",\"Dumbbell Reverse Flyes\",\"Dumbbell Shrugs\"],\"Tuesday\":[\"Dumbbell Calf Raises\",\"Dumbbell Deadlifts\",\"Dumbbell Step-ups\",\"Dumbbell Lunges\"],\"Wednesday\":[\"Dumbbell Russian Twists\",\"Dumbbell Sit-ups\",\"Dumbbell Wood Chops\",\"Dumbbell Windmills\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Shoulder Press\",\"Dumbbell Triceps Extension\",\"Dumbbell Pullover\",\"Dumbbell Flyes\"],\"Saturday\":[\"Dumbbell Reverse Flyes\",\"Dumbbell Rows\",\"Dumbbell Hammer Curls\",\"Dumbbell Shrugs\"],\"Sunday\":[\"Rest Day\"]},\"Week 3\":{\"Monday\":[\"Dumbbell Squats\",\"Dumbbell Deadlifts\",\"Dumbbell Lunges\",\"Dumbbell Step-ups\"],\"Tuesday\":[\"Dumbbell Wood Chops\",\"Dumbbell Russian Twists\",\"Dumbbell Sit-ups\",\"Dumbbell Side Bends\"],\"Wednesday\":[\"Dumbbell Shoulder Press\",\"Dumbbell Bench Press\",\"Dumbbell Pullover\",\"Dumbbell Flyes\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Bicep Curls\",\"Dumbbell Reverse Flyes\",\"Dumbbell Shrugs\",\"Dumbbell Rows\"],\"Saturday\":[\"Dumbbell Squats\",\"Dumbbell Lunges\",\"Dumbbell Step-ups\",\"Dumbbell Deadlifts\"],\"Sunday\":[\"Rest Day\"]},\"Week 4\":{\"Monday\":[\"Dumbbell Side Bends\",\"Dumbbell Russian Twists\",\"Dumbbell Wood Chops\",\"Dumbbell Sit-ups\"],\"Tuesday\":[\"Dumbbell Shoulder Press\",\"Dumbbell Bench Press\",\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\"],\"Wednesday\":[\"Dumbbell Bicep Curls\",\"Dumbbell Reverse Flyes\",\"Dumbbell Shrugs\",\"Dumbbell Rows\"],\"Thursday\":[\"Rest Day\"],\"Friday\":[\"Dumbbell Calf Raises\",\"Dumbbell Squats\",\"Dumbbell Lunges\",\"Dumbbell Deadlifts\"],\"Saturday\":[\"Dumbbell Side Bends\",\"Dumbbell Russian Twists\",\"Dumbbell Sit-ups\",\"Dumbbell Windmills\"],\"Sunday\":[\"Rest Day\"]}},\"generated_at\":\"2025-09-13 04:21:08\"}', '2025-09-13 02:21:08', '2025-09-13 02:21:08', 0, 0, 0, '2025-09-14 01:45:01'),
(23, 4, 'weight_loss', 3, 12, '{\"weekly_plan\":{\"Week 1\":{\"Day 1\":[\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\",\"Dumbbell Pullover\",\"Dumbbell Bench Press\"],\"Day 2\":[\"Dumbbell Shrugs\",\"Dumbbell Hammer Curls\",\"Dumbbell Bicep Curls\",\"Dumbbell Reverse Flyes\"],\"Day 3\":[\"Rest Day\"],\"Day 4\":[\"Dumbbell Calf Raises\",\"Dumbbell Squats\",\"Dumbbell Lunges\",\"Dumbbell Step-ups\"],\"Day 5\":[\"Dumbbell Wood Chops\",\"Dumbbell Russian Twists\",\"Dumbbell Side Bends\",\"Dumbbell Sit-ups\"],\"Day 6\":[\"Rest Day\"],\"Day 7\":[\"Dumbbell Flyes\",\"Dumbbell Shoulder Press\",\"Dumbbell Bench Press\",\"Dumbbell Pullover\"]},\"Week 2\":{\"Day 1\":[\"Dumbbell Shrugs\",\"Dumbbell Reverse Flyes\",\"Dumbbell Bicep Curls\",\"Dumbbell Hammer Curls\"],\"Day 2\":[\"Dumbbell Lunges\",\"Dumbbell Squats\",\"Dumbbell Deadlifts\",\"Dumbbell Step-ups\"],\"Day 3\":[\"Dumbbell Russian Twists\",\"Dumbbell Sit-ups\",\"Dumbbell Windmills\",\"Dumbbell Wood Chops\"],\"Day 4\":[\"Rest Day\"],\"Day 5\":[\"Dumbbell Flyes\",\"Dumbbell Triceps Extension\",\"Dumbbell Shoulder Press\",\"Dumbbell Bench Press\"],\"Day 6\":[\"Rest Day\"],\"Day 7\":[\"Dumbbell Bicep Curls\",\"Dumbbell Reverse Flyes\",\"Dumbbell Shrugs\",\"Dumbbell Hammer Curls\"]},\"Week 3\":{\"Day 1\":[\"Dumbbell Squats\",\"Dumbbell Calf Raises\",\"Dumbbell Deadlifts\",\"Dumbbell Step-ups\"],\"Day 2\":[\"Rest Day\"],\"Day 3\":[\"Dumbbell Wood Chops\",\"Dumbbell Russian Twists\",\"Dumbbell Sit-ups\",\"Dumbbell Windmills\"],\"Day 4\":[\"Rest Day\"],\"Day 5\":[\"Dumbbell Triceps Extension\",\"Dumbbell Bench Press\",\"Dumbbell Pullover\",\"Dumbbell Flyes\"],\"Day 6\":[\"Dumbbell Bicep Curls\",\"Dumbbell Reverse Flyes\",\"Dumbbell Shrugs\",\"Dumbbell Rows\"],\"Day 7\":[\"Dumbbell Calf Raises\",\"Dumbbell Deadlifts\",\"Dumbbell Lunges\",\"Dumbbell Step-ups\"]},\"Week 4\":{\"Day 1\":[\"Dumbbell Windmills\",\"Dumbbell Wood Chops\",\"Dumbbell Sit-ups\",\"Dumbbell Russian Twists\"],\"Day 2\":[\"Dumbbell Triceps Extension\",\"Dumbbell Shoulder Press\",\"Dumbbell Flyes\",\"Dumbbell Bench Press\"],\"Day 3\":[\"Rest Day\"],\"Day 4\":[\"Dumbbell Shrugs\",\"Dumbbell Reverse Flyes\",\"Dumbbell Bicep Curls\",\"Dumbbell Hammer Curls\"],\"Day 5\":[\"Rest Day\"],\"Day 6\":[\"Dumbbell Squats\",\"Dumbbell Lunges\",\"Dumbbell Calf Raises\",\"Dumbbell Deadlifts\"],\"Day 7\":[\"Dumbbell Wood Chops\",\"Dumbbell Russian Twists\",\"Dumbbell Sit-ups\",\"Dumbbell Side Bends\"]}},\"generated_at\":\"2025-09-14 04:19:14\"}', '2025-09-14 02:19:14', '2025-09-14 02:19:14', 0, 0, 0, '2025-09-14 02:19:14');

-- --------------------------------------------------------

--
-- Table structure for table `weekly_plans`
--

CREATE TABLE `weekly_plans` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `week_number` int(11) NOT NULL,
  `plan` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`plan`)),
  `sets` int(11) NOT NULL,
  `reps` int(11) NOT NULL,
  `goal` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `weekly_plans`
--

INSERT INTO `weekly_plans` (`id`, `user_id`, `week_number`, `plan`, `sets`, `reps`, `goal`, `created_at`) VALUES
(6, 4, 1, '{\"Monday\":[\"Push-Ups - Close Triceps Position (body only)\",\"Incline Push-Up (body only)\",\"Cross Body Hammer Curl (dumbbell)\",\"Incline Push-Up Close-Grip (body only)\",\"Elbow to Knee (body only)\"],\"Tuesday\":[\"Calf Raise On A Dumbbell (dumbbell)\",\"Decline Dumbbell Flyes (dumbbell)\",\"Push-Ups With Feet Elevated (body only)\",\"Seated Glute (body only)\",\"Inchworm (body only)\"],\"Wednesday\":[\"Incline Push-Up Reverse Grip (body only)\",\"3/4 Sit-Up (body only)\",\"Zottman Preacher Curl (dumbbell)\",\"Leg Pull-In (body only)\",\"Dumbbell Seated One-Leg Calf Raise (dumbbell)\"],\"Thursday\":[\"Knee Tuck Jump (body only)\",\"Glute Kickback (body only)\",\"Pushups (Close and Wide Hand Positions) (body only)\",\"Seated Bent-Over Rear Delt Raise (dumbbell)\",\"Air Bike (body only)\"],\"Friday\":[\"Seated Biceps (body only)\",\"Wind Sprints (body only)\",\"Standing Dumbbell Straight-Arm Front Delt Raise Above Head (dumbbell)\",\"Dumbbell Seated Box Jump (dumbbell)\",\"Spider Crawl (body only)\"],\"Saturday\":[\"Side Lateral Raise (dumbbell)\",\"Body Tricep Press (body only)\",\"Cross-Body Crunch (body only)\",\"Double Leg Butt Kick (body only)\",\"Single Leg Butt Kick (body only)\"],\"Sunday\":[\"Dumbbell Bicep Curl (dumbbell)\",\"Hammer Grip Incline DB Bench Press (dumbbell)\",\"Bottoms Up (body only)\",\"Lying Crossover (body only)\",\"Front Leg Raises (body only)\"]}', 3, 15, 'weight loss', '2025-09-05 04:28:43'),
(7, 4, 1, '{\"Monday\":[\"Lying Glute (body only)\",\"Close-Grip Dumbbell Press (dumbbell)\",\"Scissors Jump (body only)\",\"Cuban Press (dumbbell)\",\"Seated Triceps Press (dumbbell)\"],\"Tuesday\":[\"Lying Crossover (body only)\",\"Dumbbell Lying Rear Lateral Raise (dumbbell)\",\"Flutter Kicks (body only)\",\"Dumbbell Bench Press with Neutral Grip (dumbbell)\",\"Lying Supine Dumbbell Curl (dumbbell)\"],\"Wednesday\":[\"Double Leg Butt Kick (body only)\",\"Palms-Up Dumbbell Wrist Curl Over A Bench (dumbbell)\",\"Bodyweight Squat (body only)\",\"Close-Grip Push-Up off of a Dumbbell (body only)\",\"Flat Bench Lying Leg Raise (body only)\"],\"Thursday\":[\"Clock Push-Up (body only)\",\"Single Dumbbell Raise (dumbbell)\",\"Reverse Crunch (body only)\",\"Seated Flat Bench Leg Pull-In (body only)\",\"Straight-Arm Dumbbell Pullover (dumbbell)\"],\"Friday\":[\"Pullups (body only)\",\"Seated One-Arm Dumbbell Palms-Up Wrist Curl (dumbbell)\",\"Standing Palm-In One-Arm Dumbbell Press (dumbbell)\",\"Bent Over Two-Dumbbell Row (dumbbell)\",\"90/90 Hamstring (body only)\"],\"Saturday\":[\"Dumbbell Raise (dumbbell)\",\"Decline Dumbbell Flyes (dumbbell)\",\"Single Leg Glute Bridge (body only)\",\"Seated One-Arm Dumbbell Palms-Down Wrist Curl (dumbbell)\",\"Incline Push-Up Reverse Grip (body only)\"],\"Sunday\":[\"Isometric Chest Squeezes (body only)\",\"Standing Dumbbell Press (dumbbell)\",\"One-Arm Side Laterals (dumbbell)\",\"Bench Dips (body only)\",\"Iron Cross (dumbbell)\"]}', 3, 15, 'weight loss', '2025-09-05 04:29:06'),
(8, 19, 1, '{\"Monday\":[\"Concentration Curls (dumbbell)\",\"Dumbbell Bench Press (dumbbell)\",\"Arnold Dumbbell Press (dumbbell)\",\"Zottman Preacher Curl (dumbbell)\",\"Decline Dumbbell Flyes (dumbbell)\"],\"Tuesday\":[\"Hammer Grip Incline DB Bench Press (dumbbell)\",\"Incline Hammer Curls (dumbbell)\",\"Dumbbell Squat (dumbbell)\",\"Dumbbell Lying Rear Lateral Raise (dumbbell)\",\"Dumbbell Bicep Curl (dumbbell)\"],\"Wednesday\":[\"Middle Back Shrug (dumbbell)\",\"Vertical Swing (dumbbell)\",\"Decline Dumbbell Triceps Extension (dumbbell)\",\"Dumbbell Incline Shoulder Raise (dumbbell)\",\"Bent Over Two-Dumbbell Row (dumbbell)\"],\"Thursday\":[\"Preacher Hammer Dumbbell Curl (dumbbell)\",\"Standing Dumbbell Reverse Curl (dumbbell)\",\"Seated Dumbbell Press (dumbbell)\",\"Bent Over Dumbbell Rear Delt Raise With Head On Bench (dumbbell)\",\"Front Incline Dumbbell Raise (dumbbell)\"],\"Friday\":[\"Incline Dumbbell Curl (dumbbell)\",\"Dumbbell Step Ups (dumbbell)\",\"Iron Cross (dumbbell)\",\"Close-Grip Dumbbell Press (dumbbell)\",\"Standing Dumbbell Straight-Arm Front Delt Raise Above Head (dumbbell)\"],\"Saturday\":[\"Lying One-Arm Lateral Raise (dumbbell)\",\"Dumbbell Shoulder Press (dumbbell)\",\"Dumbbell One-Arm Upright Row (dumbbell)\",\"One Arm Supinated Dumbbell Triceps Extension (dumbbell)\",\"Dumbbell Lying Pronation (dumbbell)\"],\"Sunday\":[\"Straight-Arm Dumbbell Pullover (dumbbell)\",\"Seated One-Arm Dumbbell Palms-Up Wrist Curl (dumbbell)\",\"Single Dumbbell Raise (dumbbell)\",\"Standing Bent-Over One-Arm Dumbbell Triceps Extension (dumbbell)\",\"Dumbbell Flyes (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-05 04:40:58'),
(9, 25, 1, '{\"Monday\":[\"Incline Dumbbell Curl (dumbbell)\",\"Incline Dumbbell Flyes - With A Twist (dumbbell)\",\"Bent Over Two-Dumbbell Row (dumbbell)\",\"Lying Rear Delt Raise (dumbbell)\",\"Dumbbell Bench Press with Neutral Grip (dumbbell)\"],\"Tuesday\":[\"Seated Dumbbell Palms-Up Wrist Curl (dumbbell)\",\"Incline Dumbbell Bench With Palms Facing In (dumbbell)\",\"Dumbbell Lunges (dumbbell)\",\"Straight-Arm Dumbbell Pullover (dumbbell)\",\"Concentration Curls (dumbbell)\"],\"Wednesday\":[\"One-Arm Dumbbell Row (dumbbell)\",\"Seated Dumbbell Press (dumbbell)\",\"Dumbbell One-Arm Upright Row (dumbbell)\",\"Dumbbell Floor Press (dumbbell)\",\"Standing Dumbbell Reverse Curl (dumbbell)\"],\"Thursday\":[\"Bent Over Dumbbell Rear Delt Raise With Head On Bench (dumbbell)\",\"One-Arm Flat Bench Dumbbell Flye (dumbbell)\",\"Hammer Grip Incline DB Bench Press (dumbbell)\",\"Incline Inner Biceps Curl (dumbbell)\",\"Dumbbell Incline Row (dumbbell)\"],\"Friday\":[\"Plie Dumbbell Squat (dumbbell)\",\"Decline Dumbbell Bench Press (dumbbell)\",\"Dumbbell Lying Pronation (dumbbell)\",\"Tate Press (dumbbell)\",\"Calf Raise On A Dumbbell (dumbbell)\"],\"Saturday\":[\"Standing Alternating Dumbbell Press (dumbbell)\",\"Stiff-Legged Dumbbell Deadlift (dumbbell)\",\"Single Dumbbell Raise (dumbbell)\",\"Dumbbell Side Bend (dumbbell)\",\"Middle Back Shrug (dumbbell)\"],\"Sunday\":[\"Standing Bent-Over One-Arm Dumbbell Triceps Extension (dumbbell)\",\"Cuban Press (dumbbell)\",\"Tricep Dumbbell Kickback (dumbbell)\",\"Iron Cross (dumbbell)\",\"Front Dumbbell Raise (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-05 04:52:39'),
(10, 25, 1, '{\"Monday\":[\"Isometric Neck Exercise - Sides (body only)\",\"Incline Dumbbell Flyes (dumbbell)\",\"Concentration Curls (dumbbell)\",\"Dumbbell Raise (dumbbell)\",\"Dumbbell Prone Incline Curl (dumbbell)\"],\"Tuesday\":[\"Air Bike (body only)\",\"Lower Back Curl (body only)\",\"Standing Dumbbell Upright Row (dumbbell)\",\"Close-Grip Push-Up off of a Dumbbell (body only)\",\"Arnold Dumbbell Press (dumbbell)\"],\"Wednesday\":[\"Calf Raise On A Dumbbell (dumbbell)\",\"Spider Crawl (body only)\",\"Dumbbell Side Bend (dumbbell)\",\"Standing Palm-In One-Arm Dumbbell Press (dumbbell)\",\"Push-Ups - Close Triceps Position (body only)\"],\"Thursday\":[\"See-Saw Press (Alternating Side Press) (dumbbell)\",\"Split Squat with Dumbbells (dumbbell)\",\"Plank (body only)\",\"Push Up to Side Plank (body only)\",\"Dumbbell Lying One-Arm Rear Lateral Raise (dumbbell)\"],\"Friday\":[\"Body-Up (body only)\",\"Side Leg Raises (body only)\",\"Pushups (body only)\",\"Decline Reverse Crunch (body only)\",\"Plie Dumbbell Squat (dumbbell)\"],\"Saturday\":[\"Single Leg Butt Kick (body only)\",\"Seated Dumbbell Inner Biceps Curl (dumbbell)\",\"Isometric Wipers (body only)\",\"Dumbbell Rear Lunge (dumbbell)\",\"Standing Alternating Dumbbell Press (dumbbell)\"],\"Sunday\":[\"Rear Leg Raises (body only)\",\"Standing Palms-In Dumbbell Press (dumbbell)\",\"Iron Cross (dumbbell)\",\"Knee Tuck Jump (body only)\",\"Dumbbell Lying Pronation (dumbbell)\"]}', 3, 15, 'weight loss', '2025-09-05 04:55:40'),
(11, 25, 1, '{\"Monday\":[\"Isometric Neck Exercise - Sides (body only)\",\"Incline Dumbbell Flyes (dumbbell)\",\"Concentration Curls (dumbbell)\",\"Dumbbell Raise (dumbbell)\",\"Dumbbell Prone Incline Curl (dumbbell)\"],\"Tuesday\":[\"Air Bike (body only)\",\"Lower Back Curl (body only)\",\"Standing Dumbbell Upright Row (dumbbell)\",\"Close-Grip Push-Up off of a Dumbbell (body only)\",\"Arnold Dumbbell Press (dumbbell)\"],\"Wednesday\":[\"Calf Raise On A Dumbbell (dumbbell)\",\"Spider Crawl (body only)\",\"Dumbbell Side Bend (dumbbell)\",\"Standing Palm-In One-Arm Dumbbell Press (dumbbell)\",\"Push-Ups - Close Triceps Position (body only)\"],\"Thursday\":[\"See-Saw Press (Alternating Side Press) (dumbbell)\",\"Split Squat with Dumbbells (dumbbell)\",\"Plank (body only)\",\"Push Up to Side Plank (body only)\",\"Dumbbell Lying One-Arm Rear Lateral Raise (dumbbell)\"],\"Friday\":[\"Body-Up (body only)\",\"Side Leg Raises (body only)\",\"Pushups (body only)\",\"Decline Reverse Crunch (body only)\",\"Plie Dumbbell Squat (dumbbell)\"],\"Saturday\":[\"Single Leg Butt Kick (body only)\",\"Seated Dumbbell Inner Biceps Curl (dumbbell)\",\"Isometric Wipers (body only)\",\"Dumbbell Rear Lunge (dumbbell)\",\"Standing Alternating Dumbbell Press (dumbbell)\"],\"Sunday\":[\"Rear Leg Raises (body only)\",\"Standing Palms-In Dumbbell Press (dumbbell)\",\"Iron Cross (dumbbell)\",\"Knee Tuck Jump (body only)\",\"Dumbbell Lying Pronation (dumbbell)\"]}', 3, 15, 'weight loss', '2025-09-06 04:01:06'),
(12, 26, 1, '{\"ppl_plan\":{\"Week 1\":{\"Push\":[\"Dumbbell Floor Press\",\"Reverse Flyes\",\"Cuban Press\",\"Standing Dumbbell Press\",\"Reverse Flyes With External Rotation\"],\"Pull\":[\"Standing Concentration Curl\",\"Standing Dumbbell Reverse Curl\",\"Preacher Hammer Dumbbell Curl\",\"Dumbbell Bicep Curl\",\"One-Arm Dumbbell Row\"],\"Legs\":[\"Split Squat with Dumbbells\",\"Dumbbell Squat\",\"Dumbbell Rear Lunge\",\"Stiff-Legged Dumbbell Deadlift\",\"Plie Dumbbell Squat\"]},\"Week 2\":{\"Push\":[\"Decline Dumbbell Bench Press\",\"Dumbbell Shoulder Press\",\"Dumbbell Bench Press with Neutral Grip\",\"Arnold Dumbbell Press\",\"Dumbbell Bench Press\"],\"Pull\":[\"Zottman Preacher Curl\",\"Seated Dumbbell Palms-Down Wrist Curl\",\"Hammer Curls\",\"Two-Arm Dumbbell Preacher Curl\",\"Seated One-Arm Dumbbell Palms-Down Wrist Curl\"],\"Legs\":[\"Dumbbell Lunges\",\"Dumbbell Squat To A Bench\"]},\"Week 3\":{\"Push\":[\"See-Saw Press (Alternating Side Press)\",\"Dumbbell Flyes\",\"One Arm Dumbbell Bench Press\",\"Seated Dumbbell Press\",\"Standing Palms-In Dumbbell Press\"],\"Pull\":[\"One Arm Dumbbell Preacher Curl\",\"Seated Dumbbell Curl\",\"Seated One-Arm Dumbbell Palms-Up Wrist Curl\",\"Incline Inner Biceps Curl\",\"Standing One-Arm Dumbbell Curl Over Incline Bench\"],\"Legs\":[\"Stiff-Legged Dumbbell Deadlift\",\"Dumbbell Lunges\",\"Plie Dumbbell Squat\",\"Dumbbell Squat To A Bench\"]},\"Week 4\":{\"Push\":[\"Cuban Press\",\"Reverse Flyes\",\"Dumbbell Floor Press\",\"Standing Dumbbell Press\",\"Reverse Flyes With External Rotation\"],\"Pull\":[\"Standing Dumbbell Reverse Curl\",\"Preacher Hammer Dumbbell Curl\",\"One-Arm Dumbbell Row\",\"Dumbbell Bicep Curl\",\"Standing Concentration Curl\"],\"Legs\":[\"Dumbbell Rear Lunge\",\"Stiff-Legged Dumbbell Deadlift\",\"Plie Dumbbell Squat\",\"Dumbbell Squat\",\"Dumbbell Squat To A Bench\"]}},\"weekly_cycle\":[\"Push\",\"Pull\",\"Legs\",\"Push\",\"Pull\",\"Legs\",\"Rest\"]}', 4, 8, 'muscle gain', '2025-09-06 06:19:09'),
(13, 27, 1, '{\"ppl_plan\":{\"Week 1\":{\"Push\":[\"Decline Dumbbell Flyes\",\"Standing Palm-In One-Arm Dumbbell Press\",\"Close-Grip Dumbbell Press\",\"Incline Dumbbell Press\",\"Standing Alternating Dumbbell Press\"],\"Pull\":[\"Preacher Hammer Dumbbell Curl\",\"Hammer Curls\",\"One-Arm Dumbbell Row\",\"Flexor Incline Dumbbell Curls\",\"Seated Dumbbell Palms-Down Wrist Curl\"],\"Legs\":[\"Dumbbell Squat\",\"Split Squat with Dumbbells\",\"Dumbbell Lunges\",\"Dumbbell Rear Lunge\",\"Plie Dumbbell Squat\"]},\"Week 2\":{\"Push\":[\"Seated Triceps Press\",\"One Arm Dumbbell Bench Press\",\"Decline Dumbbell Bench Press\",\"Standing Palms-In Dumbbell Press\",\"Tate Press\"],\"Pull\":[\"Cross Body Hammer Curl\",\"Dumbbell Incline Row\",\"Incline Dumbbell Curl\",\"Zottman Preacher Curl\",\"Concentration Curls\"],\"Legs\":[\"Stiff-Legged Dumbbell Deadlift\",\"Dumbbell Squat To A Bench\"]},\"Week 3\":{\"Push\":[\"Dumbbell Bench Press with Neutral Grip\",\"Dumbbell Floor Press\",\"Reverse Flyes With External Rotation\",\"Incline Dumbbell Flyes\",\"One-Arm Flat Bench Dumbbell Flye\"],\"Pull\":[\"Standing Concentration Curl\",\"One Arm Dumbbell Preacher Curl\",\"Standing Inner-Biceps Curl\",\"Incline Inner Biceps Curl\",\"Alternate Incline Dumbbell Curl\"],\"Legs\":[\"Stiff-Legged Dumbbell Deadlift\",\"Plie Dumbbell Squat\",\"Dumbbell Rear Lunge\",\"Dumbbell Squat To A Bench\"]},\"Week 4\":{\"Push\":[\"Incline Dumbbell Press\",\"Close-Grip Dumbbell Press\",\"Standing Alternating Dumbbell Press\",\"Standing Palm-In One-Arm Dumbbell Press\",\"Decline Dumbbell Flyes\"],\"Pull\":[\"Seated Dumbbell Palms-Down Wrist Curl\",\"Flexor Incline Dumbbell Curls\",\"Preacher Hammer Dumbbell Curl\",\"Hammer Curls\",\"One-Arm Dumbbell Row\"],\"Legs\":[\"Dumbbell Rear Lunge\",\"Split Squat with Dumbbells\",\"Plie Dumbbell Squat\",\"Dumbbell Lunges\",\"Dumbbell Squat To A Bench\"]}},\"weekly_cycle\":[\"Push\",\"Pull\",\"Legs\",\"Push\",\"Pull\",\"Legs\",\"Rest\"]}', 4, 8, 'muscle gain', '2025-09-06 06:50:17'),
(14, 28, 1, '{\"Monday\":[\"Dumbbell Bench Press with Neutral Grip (dumbbell)\",\"Dumbbell Lunges (dumbbell)\",\"Lying Rear Delt Raise (dumbbell)\",\"Dumbbell Step Ups (dumbbell)\",\"Seated Triceps Press (dumbbell)\"],\"Tuesday\":[\"Dumbbell Scaption (dumbbell)\",\"Dumbbell Bench Press (dumbbell)\",\"One-Arm Dumbbell Row (dumbbell)\",\"Reverse Flyes (dumbbell)\",\"Standing Bent-Over Two-Arm Dumbbell Triceps Extension (dumbbell)\"],\"Wednesday\":[\"Seated Bent-Over Rear Delt Raise (dumbbell)\",\"Standing Dumbbell Triceps Extension (dumbbell)\",\"Dumbbell Clean (dumbbell)\",\"Dumbbell Bicep Curl (dumbbell)\",\"Dumbbell Lying One-Arm Rear Lateral Raise (dumbbell)\"],\"Thursday\":[\"Dumbbell Incline Shoulder Raise (dumbbell)\",\"Standing Concentration Curl (dumbbell)\",\"Hammer Grip Incline DB Bench Press (dumbbell)\",\"One-Arm Side Laterals (dumbbell)\",\"One-Arm Flat Bench Dumbbell Flye (dumbbell)\"],\"Friday\":[\"Zottman Curl (dumbbell)\",\"Iron Cross (dumbbell)\",\"Dumbbell One-Arm Shoulder Press (dumbbell)\",\"Preacher Hammer Dumbbell Curl (dumbbell)\",\"Seated Dumbbell Palms-Down Wrist Curl (dumbbell)\"],\"Saturday\":[\"Alternating Deltoid Raise (dumbbell)\",\"Seated Side Lateral Raise (dumbbell)\",\"Dumbbell Alternate Bicep Curl (dumbbell)\",\"Dumbbell Floor Press (dumbbell)\",\"Alternate Hammer Curl (dumbbell)\"],\"Sunday\":[\"Dumbbell Squat (dumbbell)\",\"Hammer Curls (dumbbell)\",\"Front Two-Dumbbell Raise (dumbbell)\",\"Dumbbell One-Arm Triceps Extension (dumbbell)\",\"Seated Dumbbell Palms-Up Wrist Curl (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-06 07:35:13'),
(15, 29, 1, '{\"Monday\":[\"Front Dumbbell Raise (dumbbell)\",\"Iron Cross (dumbbell)\",\"One Arm Dumbbell Bench Press (dumbbell)\",\"Seated One-Arm Dumbbell Palms-Down Wrist Curl (dumbbell)\",\"Side Lateral Raise (dumbbell)\"],\"Tuesday\":[\"Dumbbell One-Arm Triceps Extension (dumbbell)\",\"Standing Dumbbell Upright Row (dumbbell)\",\"Alternate Hammer Curl (dumbbell)\",\"Around The Worlds (dumbbell)\",\"Front Two-Dumbbell Raise (dumbbell)\"],\"Wednesday\":[\"Concentration Curls (dumbbell)\",\"Standing Dumbbell Press (dumbbell)\",\"Vertical Swing (dumbbell)\",\"Dumbbell Rear Lunge (dumbbell)\",\"Decline Dumbbell Flyes (dumbbell)\"],\"Thursday\":[\"Seated Bent-Over One-Arm Dumbbell Triceps Extension (dumbbell)\",\"Hammer Grip Incline DB Bench Press (dumbbell)\",\"Dumbbell Bench Press with Neutral Grip (dumbbell)\",\"Dumbbell Clean (dumbbell)\",\"Dumbbell Floor Press (dumbbell)\"],\"Friday\":[\"Seated Dumbbell Palms-Down Wrist Curl (dumbbell)\",\"Plie Dumbbell Squat (dumbbell)\",\"Seated Dumbbell Inner Biceps Curl (dumbbell)\",\"Dumbbell Lunges (dumbbell)\",\"Calf Raise On A Dumbbell (dumbbell)\"],\"Saturday\":[\"One-Arm Incline Lateral Raise (dumbbell)\",\"Incline Hammer Curls (dumbbell)\",\"Standing Palm-In One-Arm Dumbbell Press (dumbbell)\",\"Single Dumbbell Raise (dumbbell)\",\"External Rotation (dumbbell)\"],\"Sunday\":[\"Dumbbell Lying Supination (dumbbell)\",\"One Arm Dumbbell Preacher Curl (dumbbell)\",\"Lying Supine Dumbbell Curl (dumbbell)\",\"Flexor Incline Dumbbell Curls (dumbbell)\",\"See-Saw Press (Alternating Side Press) (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-06 08:38:59'),
(16, 30, 1, '{\"Monday\":[\"Bent Over Dumbbell Rear Delt Raise With Head On Bench (dumbbell)\",\"Incline Dumbbell Press (dumbbell)\",\"Dumbbell Squat (dumbbell)\",\"Dumbbell Prone Incline Curl (dumbbell)\",\"Incline Dumbbell Flyes - With A Twist (dumbbell)\"],\"Tuesday\":[\"Lying Supine Dumbbell Curl (dumbbell)\",\"Seated Bent-Over One-Arm Dumbbell Triceps Extension (dumbbell)\",\"Two-Arm Dumbbell Preacher Curl (dumbbell)\",\"Seated Dumbbell Palms-Down Wrist Curl (dumbbell)\",\"Dumbbell Shrug (dumbbell)\"],\"Wednesday\":[\"Zottman Preacher Curl (dumbbell)\",\"See-Saw Press (Alternating Side Press) (dumbbell)\",\"Seated Dumbbell Press (dumbbell)\",\"Standing One-Arm Dumbbell Curl Over Incline Bench (dumbbell)\",\"One Arm Supinated Dumbbell Triceps Extension (dumbbell)\"],\"Thursday\":[\"Standing Palms-In Dumbbell Press (dumbbell)\",\"Seated Dumbbell Palms-Up Wrist Curl (dumbbell)\",\"Dumbbell Lying Pronation (dumbbell)\",\"Reverse Flyes (dumbbell)\",\"Dumbbell Alternate Bicep Curl (dumbbell)\"],\"Friday\":[\"Seated Dumbbell Curl (dumbbell)\",\"Dumbbell Lying Supination (dumbbell)\",\"Bent-Arm Dumbbell Pullover (dumbbell)\",\"Front Two-Dumbbell Raise (dumbbell)\",\"Dumbbell Bench Press with Neutral Grip (dumbbell)\"],\"Saturday\":[\"Side Lateral Raise (dumbbell)\",\"Standing One-Arm Dumbbell Triceps Extension (dumbbell)\",\"Front Dumbbell Raise (dumbbell)\",\"Dumbbell Incline Shoulder Raise (dumbbell)\",\"Dumbbell Rear Lunge (dumbbell)\"],\"Sunday\":[\"Decline Dumbbell Bench Press (dumbbell)\",\"Hammer Curls (dumbbell)\",\"Dumbbell One-Arm Upright Row (dumbbell)\",\"Dumbbell Shoulder Press (dumbbell)\",\"Dumbbell Bench Press (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-08 01:15:52'),
(17, 30, 1, '{\"Monday\":[\"Bent Over Dumbbell Rear Delt Raise With Head On Bench (dumbbell)\",\"Incline Dumbbell Press (dumbbell)\",\"Dumbbell Squat (dumbbell)\",\"Dumbbell Prone Incline Curl (dumbbell)\",\"Incline Dumbbell Flyes - With A Twist (dumbbell)\"],\"Tuesday\":[\"Lying Supine Dumbbell Curl (dumbbell)\",\"Seated Bent-Over One-Arm Dumbbell Triceps Extension (dumbbell)\",\"Two-Arm Dumbbell Preacher Curl (dumbbell)\",\"Seated Dumbbell Palms-Down Wrist Curl (dumbbell)\",\"Dumbbell Shrug (dumbbell)\"],\"Wednesday\":[\"Zottman Preacher Curl (dumbbell)\",\"See-Saw Press (Alternating Side Press) (dumbbell)\",\"Seated Dumbbell Press (dumbbell)\",\"Standing One-Arm Dumbbell Curl Over Incline Bench (dumbbell)\",\"One Arm Supinated Dumbbell Triceps Extension (dumbbell)\"],\"Thursday\":[\"Standing Palms-In Dumbbell Press (dumbbell)\",\"Seated Dumbbell Palms-Up Wrist Curl (dumbbell)\",\"Dumbbell Lying Pronation (dumbbell)\",\"Reverse Flyes (dumbbell)\",\"Dumbbell Alternate Bicep Curl (dumbbell)\"],\"Friday\":[\"Seated Dumbbell Curl (dumbbell)\",\"Dumbbell Lying Supination (dumbbell)\",\"Bent-Arm Dumbbell Pullover (dumbbell)\",\"Front Two-Dumbbell Raise (dumbbell)\",\"Dumbbell Bench Press with Neutral Grip (dumbbell)\"],\"Saturday\":[\"Side Lateral Raise (dumbbell)\",\"Standing One-Arm Dumbbell Triceps Extension (dumbbell)\",\"Front Dumbbell Raise (dumbbell)\",\"Dumbbell Incline Shoulder Raise (dumbbell)\",\"Dumbbell Rear Lunge (dumbbell)\"],\"Sunday\":[\"Decline Dumbbell Bench Press (dumbbell)\",\"Hammer Curls (dumbbell)\",\"Dumbbell One-Arm Upright Row (dumbbell)\",\"Dumbbell Shoulder Press (dumbbell)\",\"Dumbbell Bench Press (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-08 01:43:12'),
(18, 31, 1, '{\"Monday\":[\"Dumbbell Clean (dumbbell)\",\"Plie Dumbbell Squat (dumbbell)\",\"Incline Dumbbell Flyes (dumbbell)\",\"Tate Press (dumbbell)\",\"Alternating Deltoid Raise (dumbbell)\"],\"Tuesday\":[\"Seated Triceps Press (dumbbell)\",\"Standing Dumbbell Reverse Curl (dumbbell)\",\"Palms-Down Dumbbell Wrist Curl Over A Bench (dumbbell)\",\"Seated Dumbbell Curl (dumbbell)\",\"Lying Rear Delt Raise (dumbbell)\"],\"Wednesday\":[\"One Arm Supinated Dumbbell Triceps Extension (dumbbell)\",\"Incline Hammer Curls (dumbbell)\",\"Concentration Curls (dumbbell)\",\"Dumbbell Bench Press with Neutral Grip (dumbbell)\",\"One Arm Pronated Dumbbell Triceps Extension (dumbbell)\"],\"Thursday\":[\"Arnold Dumbbell Press (dumbbell)\",\"Hammer Grip Incline DB Bench Press (dumbbell)\",\"See-Saw Press (Alternating Side Press) (dumbbell)\",\"Incline Inner Biceps Curl (dumbbell)\",\"Standing Inner-Biceps Curl (dumbbell)\"],\"Friday\":[\"Side Lateral Raise (dumbbell)\",\"Around The Worlds (dumbbell)\",\"One-Arm Incline Lateral Raise (dumbbell)\",\"One-Arm Flat Bench Dumbbell Flye (dumbbell)\",\"Dumbbell Shrug (dumbbell)\"],\"Saturday\":[\"Dumbbell Lying Supination (dumbbell)\",\"Dumbbell Shoulder Press (dumbbell)\",\"Standing Dumbbell Press (dumbbell)\",\"Dumbbell Tricep Extension -Pronated Grip (dumbbell)\",\"Dumbbell Lying Rear Lateral Raise (dumbbell)\"],\"Sunday\":[\"Seated One-Arm Dumbbell Palms-Up Wrist Curl (dumbbell)\",\"Alternate Hammer Curl (dumbbell)\",\"Calf Raise On A Dumbbell (dumbbell)\",\"Dumbbell Alternate Bicep Curl (dumbbell)\",\"Dumbbell Bicep Curl (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-08 01:45:56'),
(19, 31, 1, '{\"Monday\":[\"Dumbbell Clean (dumbbell)\",\"Plie Dumbbell Squat (dumbbell)\",\"Incline Dumbbell Flyes (dumbbell)\",\"Tate Press (dumbbell)\",\"Alternating Deltoid Raise (dumbbell)\"],\"Tuesday\":[\"Seated Triceps Press (dumbbell)\",\"Standing Dumbbell Reverse Curl (dumbbell)\",\"Palms-Down Dumbbell Wrist Curl Over A Bench (dumbbell)\",\"Seated Dumbbell Curl (dumbbell)\",\"Lying Rear Delt Raise (dumbbell)\"],\"Wednesday\":[\"One Arm Supinated Dumbbell Triceps Extension (dumbbell)\",\"Incline Hammer Curls (dumbbell)\",\"Concentration Curls (dumbbell)\",\"Dumbbell Bench Press with Neutral Grip (dumbbell)\",\"One Arm Pronated Dumbbell Triceps Extension (dumbbell)\"],\"Thursday\":[\"Arnold Dumbbell Press (dumbbell)\",\"Hammer Grip Incline DB Bench Press (dumbbell)\",\"See-Saw Press (Alternating Side Press) (dumbbell)\",\"Incline Inner Biceps Curl (dumbbell)\",\"Standing Inner-Biceps Curl (dumbbell)\"],\"Friday\":[\"Side Lateral Raise (dumbbell)\",\"Around The Worlds (dumbbell)\",\"One-Arm Incline Lateral Raise (dumbbell)\",\"One-Arm Flat Bench Dumbbell Flye (dumbbell)\",\"Dumbbell Shrug (dumbbell)\"],\"Saturday\":[\"Dumbbell Lying Supination (dumbbell)\",\"Dumbbell Shoulder Press (dumbbell)\",\"Standing Dumbbell Press (dumbbell)\",\"Dumbbell Tricep Extension -Pronated Grip (dumbbell)\",\"Dumbbell Lying Rear Lateral Raise (dumbbell)\"],\"Sunday\":[\"Seated One-Arm Dumbbell Palms-Up Wrist Curl (dumbbell)\",\"Alternate Hammer Curl (dumbbell)\",\"Calf Raise On A Dumbbell (dumbbell)\",\"Dumbbell Alternate Bicep Curl (dumbbell)\",\"Dumbbell Bicep Curl (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-08 01:45:56'),
(20, 31, 1, '{\"Monday\":[\"Dumbbell Clean (dumbbell)\",\"Plie Dumbbell Squat (dumbbell)\",\"Incline Dumbbell Flyes (dumbbell)\",\"Tate Press (dumbbell)\",\"Alternating Deltoid Raise (dumbbell)\"],\"Tuesday\":[\"Seated Triceps Press (dumbbell)\",\"Standing Dumbbell Reverse Curl (dumbbell)\",\"Palms-Down Dumbbell Wrist Curl Over A Bench (dumbbell)\",\"Seated Dumbbell Curl (dumbbell)\",\"Lying Rear Delt Raise (dumbbell)\"],\"Wednesday\":[\"One Arm Supinated Dumbbell Triceps Extension (dumbbell)\",\"Incline Hammer Curls (dumbbell)\",\"Concentration Curls (dumbbell)\",\"Dumbbell Bench Press with Neutral Grip (dumbbell)\",\"One Arm Pronated Dumbbell Triceps Extension (dumbbell)\"],\"Thursday\":[\"Arnold Dumbbell Press (dumbbell)\",\"Hammer Grip Incline DB Bench Press (dumbbell)\",\"See-Saw Press (Alternating Side Press) (dumbbell)\",\"Incline Inner Biceps Curl (dumbbell)\",\"Standing Inner-Biceps Curl (dumbbell)\"],\"Friday\":[\"Side Lateral Raise (dumbbell)\",\"Around The Worlds (dumbbell)\",\"One-Arm Incline Lateral Raise (dumbbell)\",\"One-Arm Flat Bench Dumbbell Flye (dumbbell)\",\"Dumbbell Shrug (dumbbell)\"],\"Saturday\":[\"Dumbbell Lying Supination (dumbbell)\",\"Dumbbell Shoulder Press (dumbbell)\",\"Standing Dumbbell Press (dumbbell)\",\"Dumbbell Tricep Extension -Pronated Grip (dumbbell)\",\"Dumbbell Lying Rear Lateral Raise (dumbbell)\"],\"Sunday\":[\"Seated One-Arm Dumbbell Palms-Up Wrist Curl (dumbbell)\",\"Alternate Hammer Curl (dumbbell)\",\"Calf Raise On A Dumbbell (dumbbell)\",\"Dumbbell Alternate Bicep Curl (dumbbell)\",\"Dumbbell Bicep Curl (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-08 01:46:12'),
(21, 32, 1, '{\"Monday\":[\"Cuban Press (dumbbell)\",\"Dumbbell Seated Box Jump (dumbbell)\",\"Standing Dumbbell Press (dumbbell)\",\"Incline Dumbbell Flyes - With A Twist (dumbbell)\",\"Standing Palm-In One-Arm Dumbbell Press (dumbbell)\"],\"Tuesday\":[\"Standing Bent-Over Two-Arm Dumbbell Triceps Extension (dumbbell)\",\"Middle Back Shrug (dumbbell)\",\"Dumbbell Flyes (dumbbell)\",\"Arnold Dumbbell Press (dumbbell)\",\"Dumbbell Shrug (dumbbell)\"],\"Wednesday\":[\"Seated Triceps Press (dumbbell)\",\"Bent-Arm Dumbbell Pullover (dumbbell)\",\"Standing Palms-In Dumbbell Press (dumbbell)\",\"Alternate Hammer Curl (dumbbell)\",\"Dumbbell Lying Supination (dumbbell)\"],\"Thursday\":[\"Front Incline Dumbbell Raise (dumbbell)\",\"Iron Cross (dumbbell)\",\"Hammer Curls (dumbbell)\",\"Lying Dumbbell Tricep Extension (dumbbell)\",\"Decline Dumbbell Flyes (dumbbell)\"],\"Friday\":[\"One-Arm Flat Bench Dumbbell Flye (dumbbell)\",\"Single Dumbbell Raise (dumbbell)\",\"One-Arm Dumbbell Row (dumbbell)\",\"Side Lateral Raise (dumbbell)\",\"Flexor Incline Dumbbell Curls (dumbbell)\"],\"Saturday\":[\"Decline Dumbbell Triceps Extension (dumbbell)\",\"Palms-Down Dumbbell Wrist Curl Over A Bench (dumbbell)\",\"Standing Bent-Over One-Arm Dumbbell Triceps Extension (dumbbell)\",\"Dumbbell Shoulder Press (dumbbell)\",\"Incline Hammer Curls (dumbbell)\"],\"Sunday\":[\"Dumbbell One-Arm Triceps Extension (dumbbell)\",\"Lying One-Arm Lateral Raise (dumbbell)\",\"Dumbbell Step Ups (dumbbell)\",\"Dumbbell Floor Press (dumbbell)\",\"Dumbbell One-Arm Upright Row (dumbbell)\"]}', 4, 8, 'muscle gain', '2025-09-08 02:22:53');

-- --------------------------------------------------------

--
-- Table structure for table `workouts`
--

CREATE TABLE `workouts` (
  `workout_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `category` varchar(50) NOT NULL,
  `exercise_name` varchar(100) NOT NULL,
  `sets` int(11) NOT NULL,
  `reps` int(11) NOT NULL,
  `note` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('planned','completed') NOT NULL DEFAULT 'planned'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `workouts`
--

INSERT INTO `workouts` (`workout_id`, `user_id`, `date`, `category`, `exercise_name`, `sets`, `reps`, `note`, `created_at`, `status`) VALUES
(17, 3, '2024-07-02', 'Core', 'Plank', 3, 1, 'Plank duration felt short, increase next time', '2025-07-04 11:43:57', 'completed'),
(18, 4, '2024-07-03', 'Lower Body', 'Squats', 4, 15, 'Legs sore but manageable', '2025-07-04 11:43:57', 'completed'),
(21, 3, '2024-07-05', 'Core', 'Sit-ups', 4, 20, 'Good form maintained', '2025-07-04 11:43:57', 'completed'),
(25, 4, '2025-07-25', 'Biceps', 'Hammer Curls', 3, 12, '', '2025-07-25 08:47:20', 'planned'),
(28, 4, '2025-08-20', 'Triceps', 'Overhead Extensions', 3, 10, '', '2025-08-20 00:43:55', 'planned');

-- --------------------------------------------------------

--
-- Table structure for table `workout_sessions`
--

CREATE TABLE `workout_sessions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `exercise_name` varchar(255) NOT NULL,
  `completed_reps` int(11) DEFAULT 0,
  `target_reps` int(11) DEFAULT 0,
  `duration_seconds` int(11) DEFAULT 0,
  `date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `workout_sessions`
--

INSERT INTO `workout_sessions` (`id`, `user_id`, `exercise_name`, `completed_reps`, `target_reps`, `duration_seconds`, `date`, `created_at`) VALUES
(1, 32, 'Dumbbell Triceps Extension', 24, 32, 20, '2025-09-09', '2025-09-09 04:15:03'),
(2, 32, 'Dumbbell Pullover', 24, 32, 15, '2025-09-09', '2025-09-09 04:15:34');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `camera_workouts`
--
ALTER TABLE `camera_workouts`
  ADD PRIMARY KEY (`workout_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `email_verifications`
--
ALTER TABLE `email_verifications`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `favorites`
--
ALTER TABLE `favorites`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`,`recipe_id`);

--
-- Indexes for table `meal_plans`
--
ALTER TABLE `meal_plans`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `onboarding_data`
--
ALTER TABLE `onboarding_data`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `user_workout_plans`
--
ALTER TABLE `user_workout_plans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `weekly_plans`
--
ALTER TABLE `weekly_plans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `workouts`
--
ALTER TABLE `workouts`
  ADD PRIMARY KEY (`workout_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `workout_sessions`
--
ALTER TABLE `workout_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `camera_workouts`
--
ALTER TABLE `camera_workouts`
  MODIFY `workout_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `email_verifications`
--
ALTER TABLE `email_verifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT for table `favorites`
--
ALTER TABLE `favorites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `meal_plans`
--
ALTER TABLE `meal_plans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `onboarding_data`
--
ALTER TABLE `onboarding_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `user_workout_plans`
--
ALTER TABLE `user_workout_plans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `weekly_plans`
--
ALTER TABLE `weekly_plans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `workouts`
--
ALTER TABLE `workouts`
  MODIFY `workout_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `workout_sessions`
--
ALTER TABLE `workout_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `camera_workouts`
--
ALTER TABLE `camera_workouts`
  ADD CONSTRAINT `camera_workouts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `favorites`
--
ALTER TABLE `favorites`
  ADD CONSTRAINT `favorites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_workout_plans`
--
ALTER TABLE `user_workout_plans`
  ADD CONSTRAINT `user_workout_plans_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `workouts`
--
ALTER TABLE `workouts`
  ADD CONSTRAINT `workouts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `workout_sessions`
--
ALTER TABLE `workout_sessions`
  ADD CONSTRAINT `workout_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
