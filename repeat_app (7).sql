-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 05, 2025 at 05:11 AM
-- Server version: 10.4.22-MariaDB
-- PHP Version: 7.3.33

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `email_verifications`
--

INSERT INTO `email_verifications` (`id`, `email`, `code`, `created_at`) VALUES
(23, 'johnlloydguevarra0405@gmail.com', '350208', '2025-08-19 14:21:26'),
(27, 'johnlloydguevarra2@gmail.com', '401842', '2025-08-19 14:51:51'),
(28, 'deramosmichael27@gmail.com', '969745', '2025-08-25 13:47:03');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `meal_plans`
--

INSERT INTO `meal_plans` (`id`, `user_id`, `time_frame`, `start_date`, `meal_plan`, `created_at`, `updated_at`) VALUES
(4, 6, 'day', NULL, '{\"meals\":[{\"id\":636026,\"image\":\"Breakfast-Biscuits-and-Gravy-636026.jpg\",\"imageType\":\"jpg\",\"title\":\"Breakfast Biscuits and Gravy\",\"readyInMinutes\":45,\"servings\":4,\"sourceUrl\":\"http://www.foodista.com/recipe/S8F5B5H4/breakfast-biscuits-and-gravy\"},{\"id\":991010,\"image\":\"chicken-ranch-burgers-991010.jpg\",\"imageType\":\"jpg\",\"title\":\"Chicken Ranch Burgers\",\"readyInMinutes\":25,\"servings\":3,\"sourceUrl\":\"https://www.pinkwhen.com/chicken-ranch-burgers-recipe/\"},{\"id\":650487,\"image\":\"Lusciously-Lemony-Lentil-Soup-650487.jpg\",\"imageType\":\"jpg\",\"title\":\"Lusciously Lemony Lentil Soup\",\"readyInMinutes\":45,\"servings\":1,\"sourceUrl\":\"https://www.foodista.com/recipe/RFKZ88M8/lusciously-lemony-lentil-soup\"}],\"nutrients\":{\"calories\":2500.18,\"protein\":127.55,\"fat\":169.51,\"carbohydrates\":113.75}}', '2025-07-30 06:59:10', '2025-07-30 07:03:35'),
(5, 9, 'day', NULL, '{\"meals\":[{\"id\":1100990,\"image\":\"blueberry-chocolate-cocao-superfood-pancakes-gluten-free-paleo-vegan-1100990.jpg\",\"imageType\":\"jpg\",\"title\":\"Blueberry, Chocolate & Cocao Superfood Pancakes - Gluten-Free/Paleo/Vegan\",\"readyInMinutes\":30,\"servings\":2,\"sourceUrl\":\"https://www.foodista.com/recipe/35NX6PZB/blueberry-chocolate-cocao-superfood-pancakes-gluten-free-paleo-vegan\"},{\"id\":642681,\"image\":\"Fesenjan-642681.jpg\",\"imageType\":\"jpg\",\"title\":\"Fesenjan Chicken Stew\",\"readyInMinutes\":30,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/KRVYLC3H/fesenjan\"},{\"id\":661055,\"image\":\"Spicy-Chili-w-Boneless-Beef-Short-Ribs-661055.jpg\",\"imageType\":\"jpg\",\"title\":\"Spicy Chili w Boneless Beef Short Ribs\",\"readyInMinutes\":45,\"servings\":6,\"sourceUrl\":\"http://www.foodista.com/recipe/Y4HNTZ6S/spicy-chili-w-boneless-beef-short-ribs\"}],\"nutrients\":{\"calories\":2491.53,\"protein\":138.03,\"fat\":151.77,\"carbohydrates\":153.59}}', '2025-08-13 07:15:46', '2025-08-13 07:15:46'),
(6, 13, 'day', NULL, '{\"meals\":[{\"id\":1957598,\"image\":\"low-carb-keto-pancakes-1957598.jpg\",\"imageType\":\"jpg\",\"title\":\"Low Carb Keto Pancakes\",\"readyInMinutes\":15,\"servings\":2,\"sourceUrl\":\"https://spoonacular.com/site-1721579912124\"},{\"id\":643634,\"image\":\"Fresh-Tomatoes-With-Beans-and-Macaroni-643634.jpg\",\"imageType\":\"jpg\",\"title\":\"Macaroni with Fresh Tomatoes and Beans\",\"readyInMinutes\":25,\"servings\":4,\"sourceUrl\":\"https://www.foodista.com/recipe/LY45JTQD/fresh-tomatoes-with-beans-and-macaroni\"},{\"id\":636256,\"image\":\"Broiled-Crab-Cakes-636256.jpg\",\"imageType\":\"jpg\",\"title\":\"Broiled Crab Cakes\",\"readyInMinutes\":45,\"servings\":3,\"sourceUrl\":\"https://www.foodista.com/recipe/RBLXQMWS/broiled-crabcakes\"}],\"nutrients\":{\"calories\":1500.07,\"protein\":76.73,\"fat\":75.83,\"carbohydrates\":133.98}}', '2025-08-18 06:23:44', '2025-08-18 06:23:44');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `onboarding_data`
--

INSERT INTO `onboarding_data` (`id`, `user_id`, `gender`, `birthdate`, `body_type`, `current_weight`, `target_weight`, `height`, `goal`, `has_injury`, `injury_details`, `diet_preference`, `allergies`, `created_at`) VALUES
(17, 4, 'Male', '2007-01-01', 'Overweight', '90', '80', '190', 'Weight Loss', 1, 'Knee Pain', 'Low-Carb', 'None', '2025-07-08 10:04:09'),
(30, 19, 'Male', '2007-08-31', 'Normal', '70', '75', '175', 'Muscle Gain', 1, 'Shoulder Injury', 'Dairy Free', 'Milk', '2025-08-19 06:22:43'),
(35, 24, 'Male', '2007-08-25', 'Overweight', '95', '75', '190', 'Weight Loss', 0, 'None', 'Low Fat', 'None', '2025-08-25 05:48:31');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `email`, `password`, `name`, `created_at`, `is_onboarded`) VALUES
(3, 'sample1@gmail.com', '$2y$10$cfgwRBhztrlOzAOQD89kkel65R0vY0UpJRD5w8sfqRvEfZXHW/t3a', 'Sample', '2025-06-25 08:19:18', 0),
(4, 'user@example.com', '$2y$10$VIOGkFDh1sD8FXqMBkPrR.0/.1PTI4gur3MCymM39KJM2q2JPsUO2', 'John Doe', '2025-06-26 07:17:53', 1),
(19, 'johnlloydguevarra0405@gmail.com', '$2y$10$8jm7bN63Vp.t45e492pnJOGalkSgSQGdncEcHNZwlPydo1brETapi', 'John Lloyd Guevarra', '2025-08-19 06:22:08', 1),
(24, 'deramosmichael27@gmail.com', '$2y$10$Ww/5s5yDXh9SI5nwz1.Ymu8/nRgaFoIMOD7FyjdFDPC2gEU6Rw6he', 'myke', '2025-08-25 05:47:33', 1);

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `workouts`
--

INSERT INTO `workouts` (`workout_id`, `user_id`, `date`, `category`, `exercise_name`, `sets`, `reps`, `note`, `created_at`, `status`) VALUES
(17, 3, '2024-07-02', 'Core', 'Plank', 3, 1, 'Plank duration felt short, increase next time', '2025-07-04 11:43:57', 'completed'),
(18, 4, '2024-07-03', 'Lower Body', 'Squats', 4, 15, 'Legs sore but manageable', '2025-07-04 11:43:57', 'completed'),
(21, 3, '2024-07-05', 'Core', 'Sit-ups', 4, 20, 'Good form maintained', '2025-07-04 11:43:57', 'completed'),
(25, 4, '2025-07-25', 'Biceps', 'Hammer Curls', 3, 12, '', '2025-07-25 08:47:20', 'planned'),
(28, 4, '2025-08-20', 'Triceps', 'Overhead Extensions', 3, 10, '', '2025-08-20 00:43:55', 'planned');

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `favorites`
--
ALTER TABLE `favorites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `meal_plans`
--
ALTER TABLE `meal_plans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `onboarding_data`
--
ALTER TABLE `onboarding_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `weekly_plans`
--
ALTER TABLE `weekly_plans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `workouts`
--
ALTER TABLE `workouts`
  MODIFY `workout_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

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
-- Constraints for table `workouts`
--
ALTER TABLE `workouts`
  ADD CONSTRAINT `workouts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
