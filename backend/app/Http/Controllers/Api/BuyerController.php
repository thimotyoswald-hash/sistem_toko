<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Buyer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BuyerController extends Controller
{
    public function index(Request $request): JsonResource
    {
        return JsonResource::collection(
            Buyer::query()
                ->when($request->filled('q'), fn ($query) => $query->where('name', 'like', '%'.$request->string('q').'%'))
                ->orderBy('name')
                ->limit(100)
                ->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $buyer = Buyer::create($request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:500'],
        ]));

        return JsonResource::make($buyer)->response()->setStatusCode(201);
    }
}
