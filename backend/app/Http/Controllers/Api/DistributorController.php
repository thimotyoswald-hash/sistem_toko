<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Distributor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DistributorController extends Controller
{
    public function index(): JsonResource
    {
        return JsonResource::collection(Distributor::query()->orderBy('name')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $distributor = Distributor::create($this->validated($request));

        return JsonResource::make($distributor)->response()->setStatusCode(201);
    }

    public function update(Request $request, Distributor $distributor): JsonResource
    {
        $distributor->update($this->validated($request));

        return JsonResource::make($distributor);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:500'],
        ]);
    }
}
