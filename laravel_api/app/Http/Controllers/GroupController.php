<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use app\Models\Group;

class GroupController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $groups = Group::all();
        return response()->json($groups);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
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
        $group = Group::findorFail($id);
        
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
