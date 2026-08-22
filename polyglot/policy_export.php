<?php
declare(strict_types=1);
final readonly class GravityPolicy { public function __construct(public string $slug, public float $angle, public float $strength, public int $stability, public string $message) {} }
function export_policy_manifest(array $rows): string {
    $policies = array_map(fn(array $row) => new GravityPolicy(slug:(string)$row['slug'], angle:fmod((float)$row['angle_degrees']+360.0,360.0), strength:max(0.0,min(100.0,(float)$row['strength_percent'])), stability:max(0,min(100,(int)$row['stability'])), message:trim((string)$row['field_message'])), $rows);
    usort($policies, fn(GravityPolicy $a, GravityPolicy $b) => $b->stability <=> $a->stability);
    return json_encode(['schema'=>1,'policies'=>$policies], JSON_THROW_ON_ERROR|JSON_PRETTY_PRINT);
}
function checksum_manifest(string $manifest): string { return strtoupper(substr(hash('sha256',$manifest),0,16)); }
