class VoteConsensus
  MIN_SELECTIONS = 5   # accept gender if at least this many votes
  VOTE_THRESHOLD = 0.8 # and at least this ratio of votes were for it

  attr_reader :vote_counts

  def initialize(vote_counts)
    @vote_counts = vote_counts
  end

  def totals
    known_gender = {}
    vote_counts.to_hash.each do |politician_id, votes|
      total = votes.values.reduce(&:+)
      if total < MIN_SELECTIONS
        warn "Not enough votes for #{politician_id}"
        next
      end
      winner = votes.find { |k, v| (v.to_f / total) > VOTE_THRESHOLD } or begin
        warn "Unclear gender vote pattern: #{votes.to_hash}"
        next
      end
      next if winner.first == :skip
      known_gender[politician_id] = winner.first.to_s
    end
    known_gender
  end
end
