<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClassController;
use App\Http\Controllers\GroupController;
use App\Http\Controllers\SessionController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\CommuneController;
use App\Http\Controllers\AuthController;


Route::middleware('api')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware(['api', 'auth:sanctum'])->group(function () {
    ////////////////////////classes.////////////////////
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        $user = $request->user();
        return response()->json([
            'success' => true,
            'data' => [
                'user' => $user,
                'role_name' => $user->role_name,
            ]
        ]);
    });
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
    Route::post('/students/{groupId}/import', [StudentController::class, 'import']);
    Route::get('/students/{groupId}',[StudentController::class,'index']);
    Route::get('/studentsq',[StudentController::class,'index']);
    Route::post('/students',[StudentController::class,'store']);
    Route::put('/students/{studentId}',[StudentController::class,'update']);
    Route::delete('/students/{studentId}',[StudentController::class,'destroy']);
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
    //////////////////communes/////////////////////////////////////////////////////////////////////////////////
    Route::get('/communes', [CommuneController::class, 'index']);
    Route::post('/communes', [CommuneController::class, 'store']);
    Route::get('/communes/{id}', [CommuneController::class, 'show']);
    Route::put('/communes/{id}', [CommuneController::class, 'update']);
    Route::delete('/communes/{id}', [CommuneController::class, 'destroy']);
    

});
