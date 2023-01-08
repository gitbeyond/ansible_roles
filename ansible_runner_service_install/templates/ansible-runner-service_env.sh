{%for var in runner_service_run_env_vars%}
{{var['name']}}={{var['value']}}
{%endfor%}
