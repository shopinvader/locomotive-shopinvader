def build_services_for_algolia(application_id: '42', api_key: '42', roles: {})
  request = instance_double('Request', env: {})
  site    = instance_double('Site', metafields: {
    'algolia' => {
      'application_id'  => application_id,
      'api_key'         => api_key
    }.merge(roles)
  })

  allow_any_instance_of(Locomotive::Steam::SiteFinderService).to receive(:find).and_return(site)

  Locomotive::Steam::Services.build_instance(request)
end
