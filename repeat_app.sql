-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 08, 2025 at 07:10 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

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
(1, 'johnlloydguevarra2@gmail.com', '952002', '2025-06-26 16:39:17'),
(2, 'johnlloydguevarra2@gmail.com', '776665', '2025-06-26 16:40:36'),
(3, 'johnlloydguevarra0405@gmail.com', '368401', '2025-07-07 13:26:14');

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
  `preferred_sets` varchar(10) DEFAULT NULL,
  `preferred_reps` varchar(10) DEFAULT NULL,
  `has_injury` tinyint(1) DEFAULT NULL,
  `injury_details` varchar(100) DEFAULT NULL,
  `diet_preference` varchar(50) DEFAULT NULL,
  `allergies` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `onboarding_data`
--

INSERT INTO `onboarding_data` (`id`, `user_id`, `gender`, `birthdate`, `body_type`, `current_weight`, `target_weight`, `height`, `goal`, `preferred_sets`, `preferred_reps`, `has_injury`, `injury_details`, `diet_preference`, `allergies`, `created_at`) VALUES
(16, 5, 'Female', '2007-01-01', 'Normal', '61', '70', '173', 'Muscle Gain', '3', '12', 1, 'Knee Pain', 'High-Protein', 'None', '2025-07-08 05:05:03');

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
(1, 'johnlloydguevarra0405@gmail.com', '410729', 1, '2025-06-25 10:54:35'),
(2, 'johnlloydguevarra0405@gmail.com', '443043', 0, '2025-06-26 06:46:27'),
(3, 'johnlloydguevarra0405@gmail.com', '184765', 0, '2025-06-26 07:05:13'),
(4, 'johnlloydguevarra0405@gmail.com', '454097', 0, '2025-06-26 07:06:20'),
(5, 'johnlloydguevarra2@gmail.com', '499286', 0, '2025-06-26 08:50:44'),
(6, 'johnlloydguevarra2@gmail.com', '858167', 1, '2025-06-30 09:30:16');

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
(4, 'user@example.com', '$2y$10$VIOGkFDh1sD8FXqMBkPrR.0/.1PTI4gur3MCymM39KJM2q2JPsUO2', 'John Doe', '2025-06-26 07:17:53', 0),
(5, 'johnlloydguevarra2@gmail.com', '$2y$10$c0Z.SrMKhgkBVKU6q8WoauRToUj/W1YziGYPkA9BOBuNi70KRwMfK', 'Juan Tamad', '2025-06-26 08:41:07', 1),
(6, 'johnlloydguevarra0405@gmail.com', '$2y$10$my7uuEAy9fHNBd.Db2EW4ea3fPNQJXxhGlcThWvEh8QcuP3XUgtNK', 'John Lloyd Guevarra', '2025-07-07 05:26:34', 0);

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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `workouts`
--

INSERT INTO `workouts` (`workout_id`, `user_id`, `date`, `category`, `exercise_name`, `sets`, `reps`, `note`, `created_at`) VALUES
(17, 3, '2024-07-02', 'Core', 'Plank', 3, 1, 'Plank duration felt short, increase next time', '2025-07-04 11:43:57'),
(18, 4, '2024-07-03', 'Lower Body', 'Squats', 4, 15, 'Legs sore but manageable', '2025-07-04 11:43:57'),
(19, 5, '2024-07-01', 'Cardio', 'Jumping Jacks', 3, 30, 'Warm-up session', '2025-07-04 11:43:57'),
(21, 3, '2024-07-05', 'Core', 'Sit-ups', 4, 20, 'Good form maintained', '2025-07-04 11:43:57');

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
  MODIFY `workout_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `email_verifications`
--
ALTER TABLE `email_verifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `onboarding_data`
--
ALTER TABLE `onboarding_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `workouts`
--
ALTER TABLE `workouts`
  MODIFY `workout_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `camera_workouts`
--
ALTER TABLE `camera_workouts`
  ADD CONSTRAINT `camera_workouts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `workouts`
--
ALTER TABLE `workouts`
  ADD CONSTRAINT `workouts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
