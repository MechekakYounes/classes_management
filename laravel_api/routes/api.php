<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClassController;

Route::middleware('api')->group(function () {
    Route::get('/classes', [ClassController::class, 'index']);
    Route::post('/classes', [ClassController::class, 'store']);
    Route::put('/classes/{id}', [ClassController::class, 'update']);
    Route::delete('/classes/{id}', [ClassController::class, 'destroy']);

    Route::get('/grp', [GroupController::class, 'allGroups']);
    Route::get('/classes/{classId}/grp', [GroupController::class, 'index']);
    Route::post('/classes/{classId}/grp', [GroupController::class, 'store']);
    Route::put('/classes/{classId}/grp/{groupId}', [GroupController::class, 'update']);
    Route::delete('/classes/{classId}/grp/{groupId}', [GroupController::class, 'destroy']);
});
