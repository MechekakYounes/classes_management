<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Group;

class GroupController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index($classId)
    {
        $groups = Group::where('class_id', $classId)->get();
        return response()->json(['data' => $groups]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request, $classId)
    {
        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|max:255',
        ]);
        
        $group = new Group();
        $group->name = $validatedData['name'];
        $group->type = $validatedData['type'];
        $group->class_id = $classId;
        $group->save();
        
        return response()->json(['data' => $group], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show($classId, $groupId)
    {
        $group = Group::where('class_id', $classId)
                      ->where('id', $groupId)
                      ->firstOrFail();
        
        return response()->json(['data' => $group]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $classId, $groupId)
    {
        $validatedData = $request->validate([
            'name' => 'string|max:255',
            'type' => 'string|max:255',
        ]);
        
        $group = Group::where('class_id', $classId)
                      ->where('id', $groupId)
                      ->firstOrFail();
                      
        $group->update($validatedData);
        
        return response()->json(['data' => $group]);
    }
    
    /**
     * Remove the specified resource from storage.
     */
    public function destroy($classId, $groupId)
    {
        $group = Group::where('class_id', $classId)
                      ->where('id', $groupId)
                      ->firstOrFail();
        $group->delete();
        
        return response()->json(null, 204);
    }

    /**
     * Get all groups regardless of class.
     */
    public function allGroups() 
    {
        $groups = Group::all();
        return response()->json(['data' => $groups]);
    }
}