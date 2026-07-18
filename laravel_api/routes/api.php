<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\ClassController;
use App\Http\Controllers\CommuneController;
use App\Http\Controllers\GroupController;
use App\Http\Controllers\SessionController;
use App\Http\Controllers\StudentController;


Route::post('/login', [AuthController::class, 'login']);

Route::middleware(['auth:sanctum'])->group(function () {
    //logout route
    Route::post('/logout', [AuthController::class, 'logout']);

    // classes routes
    Route::middleware('permission:classes.view')->group(function () {
        Route::get('/classes', [ClassController::class, 'index']);
    });

    Route::middleware('permission:classes.create')->group(function () {
        Route::post('/classes', [ClassController::class, 'store']);
    });

    Route::middleware('permission:classes.edit')->group(function () {
        Route::put('/classes/{id}', [ClassController::class, 'update']);
    });

    Route::middleware('permission:classes.delete')->group(function () {
        Route::delete('/classes/{id}', [ClassController::class, 'destroy']);
    });

    /*
    groups routes 
    */

    Route::middleware('permission:groups.view')->group(function () {
        Route::get('/groups', [GroupController::class, 'allGroups']);
        Route::get('/classes/{classId}/groups', [GroupController::class, 'index']);
    });

    Route::middleware('permission:groups.create')->group(function () {
        Route::post('/classes/{classId}/groups', [GroupController::class, 'store']);
    });

    Route::middleware('permission:groups.edit')->group(function () {
        Route::put('/classes/{classId}/groups/{groupId}', [GroupController::class, 'update']);
    });

    Route::middleware('permission:groups.delete')->group(function () {
        Route::delete('/classes/{classId}/groups/{groupId}', [GroupController::class, 'destroy']);
    });

    /*
    Students
    */

    Route::middleware('permission:students.view')->group(function () {
        Route::get('/students/{groupId}', [StudentController::class, 'index']);
        Route::get('/students', [StudentController::class, 'index']);
    });

    Route::middleware('permission:students.create')->group(function () {
        Route::post('/students', [StudentController::class, 'store']);
        Route::post('/students/{groupId}/import', [StudentController::class, 'import']);
    });

    Route::middleware('permission:students.edit')->group(function () {
        Route::put('/students/{studentId}', [StudentController::class, 'update']);
    });

    Route::middleware('permission:students.delete')->group(function () {
        Route::delete('/students/{studentId}', [StudentController::class, 'destroy']);
    });

    /*
     Sessions
    */

    Route::middleware('permission:sessions.view')->group(function () {
        Route::get('/groups/{groupId}/session', [SessionController::class, 'index']);
    });

    Route::middleware('permission:sessions.create')->group(function () {
        Route::post('/groups/{groupId}/session', [SessionController::class, 'store']);
    });

    Route::middleware('permission:sessions.edit')->group(function () {
        Route::put('/groups/{groupId}/session/{id}', [SessionController::class, 'update']);
    });

    Route::middleware('permission:sessions.delete')->group(function () {
        Route::delete('/groups/{groupId}/session/{id}', [SessionController::class, 'destroy']);
    });

    /*
     Attendance
    */

    Route::middleware('permission:attendance.manage')->group(function () {
        Route::get('/session/{sessionId}/attendances', [AttendanceController::class, 'index']);
        Route::post('/session/{sessionId}/attendances', [AttendanceController::class, 'store']);
        Route::put('/session/{sessionId}/attendances/{attendanceId}', [AttendanceController::class, 'update']);
        Route::delete('/session/{sessionId}/attendances/{attendanceId}', [AttendanceController::class, 'destroy']);
    });

    /*
     Communes
    */

    Route::middleware('permission:communes.view')->group(function () {
        Route::get('/communes', [CommuneController::class, 'index']);
        Route::get('/communes/{id}', [CommuneController::class, 'show']);
    });

    Route::middleware('permission:communes.create')->group(function () {
        Route::post('/communes', [CommuneController::class, 'store']);
    });

    Route::middleware('permission:communes.edit')->group(function () {
        Route::put('/communes/{id}', [CommuneController::class, 'update']);
    });

    Route::middleware('permission:communes.delete')->group(function () {
        Route::delete('/communes/{id}', [CommuneController::class, 'destroy']);
    });

});