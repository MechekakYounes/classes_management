<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use app\Models\Group;

class GroupController extends Controller
{
    /**
     * Display a listing of the resource.
     * $groups = Group::where('class_id', $classId)->get();
     *  return response()->json(['data' => $groups]);
     */
    public function index()
    {   
        $groups = Group::where('class_id', $classId)->get();
        return response()->json(['data' => $groups]);
        //$groups = Group::all();
        //return response()->json($groups);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
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
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $group= new Group();
        $group->name = $request->input('name');
        $group->type = $request->input('type');
        $group->level = $request->input('level');
        //$group->class_id = 
        $group->save();

        return response()->json($group, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $group = Group::where('class_id', $classId)
                      ->where('id', $groupId)
                      ->firstOrFail();
        
        return response()->json(['data' => $group]); 
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
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
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
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
    public function destroy(string $id)
    {
        $group = Group::where('class_id', $classId)
                      ->where('id', $groupId)
                      ->firstOrFail();
        $group->delete();
        
        return response()->json(null, 204);
    }
    
    public function allGroups() 
    {
        $groups = Group::all();
        return response()->json(['data' => $groups]);
    }
}
