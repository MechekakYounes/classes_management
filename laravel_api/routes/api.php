<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClassController;
use App\Http\Controllers\GroupController;
<<<<<<< HEAD
use App\Models\Group;
=======
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

Route::middleware('api')->group(function () {
    // Classes routes
    Route::get('/classes', [ClassController::class, 'index']);
    Route::post('/classes', [ClassController::class, 'store']);
    Route::put('/classes/{id}', [ClassController::class, 'update']);
    Route::delete('/classes/{id}', [ClassController::class, 'destroy']);
<<<<<<< HEAD
    
    // Groups routes
    Route::get('/grp', [GroupController::class, 'allGroups']);
    Route::get('/classes/{classId}/grp', [GroupController::class, 'index']);
    Route::post('/classes/{classId}/grp', [GroupController::class, 'store']);
    Route::put('/classes/{classId}/grp/{groupId}', [GroupController::class, 'update']);
    Route::delete('/classes/{classId}/grp/{groupId}', [GroupController::class, 'destroy']);
});
=======

    Route::get('/groups', [GroupController::class, 'allGroups']);
    Route::get('/classes/{classId}/groups', [GroupController::class, 'index']);
    Route::post('/classes/{classId}/groups', [GroupController::class, 'store']);
    Route::put('/classes/{classId}/groups/{groupId}', [GroupController::class, 'update']);
    Route::delete('/classes/{classId}/groups/{groupId}', [GroupController::class, 'destroy']);
    
});
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318
