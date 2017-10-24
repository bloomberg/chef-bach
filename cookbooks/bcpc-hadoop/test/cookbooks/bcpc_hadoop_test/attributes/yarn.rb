default[:bcpc][:hadoop][:yarn][:fairSchedulerOpts] = {
  'userMaxAppsDefault' => 5,
  'defaultFairSharePreemptionTimeout' => 120,
  'defaultMinSharePreemptionTimeout' => 10,
  'queueMaxAMShareDefault' => 0.5,
  'defaultQueueSchedulingPolicy' => 'DRF'
}

default[:bcpc][:hadoop][:yarn][:queuePlacementPolicy] = [
  {'specified' => {'create' => 'false'}},
  {'nestedUserQueue' => {'create' => 'false',
                         'secondaryGroupExistingQueue' =>
                            {'create' => 'false'}}},
  {'nestedUserQueue' => {'name' => {'create' => 'true'}}},
  {'reject' => nil}
]
