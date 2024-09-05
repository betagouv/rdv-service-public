User.all.each { _1.update(last_name: _1.last_name.capitalize) }
Agent.all.each { _1.update(last_name: _1.last_name.capitalize) }
