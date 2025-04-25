<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClassController;
use App\Http\Controllers\GroupController;
use App\Http\Controllers\SessionController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\AttendanceController;


Route::middleware('api')->group(function () {
    ////////////////////////classes./////////////////////
    Route::get('/classes', [ClassController::class, 'index']);
    Route::post('/classes', [ClassController::class, 'store']);
    Route::put('/classes/{id}', [ClassController::class, 'update']);
    Route::delete('/classes/{id}', [ClassController::class, 'destroy']);
///////////////groups////////////////////////
    Route::get('/groups', [GroupController::class, 'allGroups']);
    Route::get('/classes/{classId}/groups', [GroupController::class, 'index']);
    Route::post('/classes/{classId}/groups', [GroupController::class, 'store']);
    Route::put('/classes/{classId}/groups/{groupId}', [GroupController::class, 'update']);
    Route::delete('/classes/{classId}/groups/{groupId}', [GroupController::class, 'destroy']);
////////////////////students/////////////////
    Route::post('/student/import', [StudentController::class, 'import']);
    Route::get('/student/by-group/{groupId}',[StudentController::class,'index']);
 ///////////session///////////////
    Route::get('/groups/{groupId}/session', [SessionController::class, 'index']);
    Route::post('/groups/{groupId}/session', [SessionController::class, 'store']);
    Route::put('/groups/{groupId}/session/{id}', [SessionController::class, 'update']);
    Route::delete('/groups/{groupId}/session/{id}', [SessionController::class, 'destroy']);
    ////////////////////attendence/////////////////////////////////////////////////
    Route::get('/session/{sessionId}/attendances', [AttendanceController::class, 'index']);
    Route::post('/session/{sessionId}/attendances', [AttendanceController::class, 'store']);
    Route::put('/session/{sessionId}/attendances/{attendanceId}', [AttendanceController::class, 'update']);
    Route::delete('/session/{sessionId}/attendances/{attendanceId}', [AttendanceController::class, 'destroy']);
});
