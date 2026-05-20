---
title: Shoji Yuen
permalink: /en/members/shoji-yuen/
lang: en
site_title: Yuen/Nakazawa Laboratory
---

<section class="page-header">
  <p class="eyebrow">Member</p>
  <h1>Shoji Yuen</h1>
  <p>Professor</p>
</section>

<section class="section member-profile">
  {% assign member = site.data.members_en | where: "slug", "shoji-yuen" | first %}
  {% if member.photo_url %}
    <img class="profile-photo" src="{{ member.photo_url }}" alt="{{ member.name }}">
  {% else %}
    <div class="avatar avatar--large" aria-hidden="true">SY</div>
  {% endif %}
  <div class="member-profile__body">
    {% if member.website or member.profile_md_url %}
      <div class="profile-block profile-block--compact">
        <p class="eyebrow">Links</p>
        {% if member.website %}
          <p><strong>Personal Page</strong><br><a class="button" href="{{ member.website }}">Open personal page</a></p>
        {% endif %}
        {% if member.profile_md_url %}
          <p><strong>Profile</strong><br><a class="button" href="{{ member.profile_md_url }}">Open profile</a></p>
        {% endif %}
      </div>
    {% else %}
      <div class="profile-block">
        <p class="eyebrow">Research Theme</p>
        <h2>Reversible Concurrent Programming, Real-time Software</h2>
        <p>I am interested in reversible computing, concurrent programming, and formal methods for real-time software. My research focuses on theories and development support techniques for mathematically ensuring the correctness and reliability of programs.</p>
      </div>
      <div class="profile-block profile-block--compact">
        <p class="eyebrow">Contact</p>
        <p><strong>Email</strong><br>yuen [at] sqlab.jp</p>
      </div>
    {% endif %}
    <a class="back-link" href="{{ '/en/members/' | relative_url }}">Back to Members</a>
  </div>
</section>
