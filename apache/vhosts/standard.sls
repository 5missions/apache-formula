{% from "apache/map.jinja" import apache with context %}

include:
  - apache

{% for id, site in salt['pillar.get']('apache:sites', {}).items() %}

{{ id }}:
  file:
    - managed
    - name: {{ apache.vhostdir }}/{{ id }}{{ apache.confext }}
    - source: {{ site.get('template_file', 'salt://apache/vhosts/standard.tmpl') }}
    - template: {{ site.get('template_engine', 'jinja') }}
    - context:
        id: {{ id|json }}
        site: {{ site|json }}
        map: {{ apache|json }}
    - require:
      - pkg: apache
    - watch_in:
      - module: apache-reload

document_root_{{ id }}:
  file:
    - directory
    - name: {{ site.get('DocumentRoot', '{0}/{1}'.format(apache.wwwdir, id)) }}
    - require:
      - pkg: apache
    - watch_in:
      - module: apache-reload

{% if grains.os_family == 'Debian' %}
a2ensite {{ id }}{{ apache.confext }}:
  cmd:
    - run
    - unless: test -f /etc/apache2/sites-enabled/{{ id }}{{ apache.confext }}
    - require:
      - file: /etc/apache2/sites-available/{{ id }}{{ apache.confext }}
    - watch_in:
      - module: apache-reload
{% endif %}

{% endfor %}
