var showMessages = function showMessages(hideAfterMilliseconds){
  $('.app-messages').addClass('slide-in');
  if(typeof hideAfterMilliseconds !== 'undefined') {
    setTimeout(hideMessages, hideAfterMilliseconds);
  }
}

var hideMessages = function hideMessages(){
  $('.app-messages').removeClass('slide-in');
  setTimeout(function(){
    $('.app-messages').empty();
  }, 1000);
}

var updateGoogleLink = function updateGoogleLink($stack){
  var link = $stack.find('li:first').data('google-link');
  $('.js-google-link').attr('href', link);
}

var updateUndoButton = function updateUndoButton(){
  var $el = $('.js-undo');
  if ($('.js-done-stack').children().length == 0) {
    $el.addClass('button--disabled');
  } else {
    $el.removeClass('button--disabled');
  }
}

var undo = function undo(cardSwipe, $stack){
  var $latestCard = $('.js-done-stack').children().eq(0);
  if ($latestCard.length === 0) return;

  if ($('.level-complete').is(':visible')) {
    $('.controls').fadeIn(200);
    $('.level-complete').fadeOut(200);
  }

  // move newly added card(s) back onto extra cards pile
  $extraCards = $('.js-extra-cards');
  while ($stack.children().length > 1) {
    $stack.children().eq(-1).prependTo($extraCards);
  }
  // Hide the colored overlay
  $('span', $latestCard).animate({opacity: 0}, cardSwipe.animationRevertSpeed);

  // move latest swiped card back onto stack
  $latestCard.prependTo($stack);
  $latestCard.animate(
    {transform: "translate(0px,0px) rotate(0deg)"},
    cardSwipe.animationRevertSpeed,
    function() {
      updateGoogleLink($stack);
      updateProgressBar($latestCard.data('choice'), 'undo');
      updateUndoButton();
    }
  );
}

var undoInit = function undoInit(cardSwipe, $stack){
  $(document).on('keydown', function(e) {
    if (e.metaKey && e.keyCode == 90) {
      undo(cardSwipe, $stack);
    }
  });

  $('.js-undo').on('click', function(ev){
    undo(cardSwipe, $stack);
  });
}

var levelComplete = function onLevelComplete(){
  $('.controls').fadeOut(200);
  $('.level-complete').fadeIn(200);
  setTimeout(trophyFlash, 200);
}

var trophyFlash = function trophyFlash(){
  $('.trophy__flash').show().animate({
    transform: 'scale(6)',
    opacity: 0
  }, 200, function(){
    $(this).css({
      display: '',
      transform: '',
      opacity: ''
    })
  });
}

var setUpProgressBar = function setUpProgressBar(){
  // Sets progress bar segment widths instantaneously,
  // based on the totals in `window.totals`.
  var total = $('.progress-bar').data('total');

  $.each(['male', 'female', 'other'], function(_i, choice){
    if(window.totals[choice] > 0){
      var width = (window.totals[choice] / total) * 100;
      getProgressBarSegment(choice).css({
        width: width + '%'
      });
    }
  });
}

var updateProgressBar = function updateProgressBar(choice, type){
  // `choice` should be one of: female, male, other, skip
  // `type` is optionally one of: done, undo (defaults to "done")

  // Clean up the arguments
  type = type || 'done';
  if (choice === 'skip') {
    choice = 'other';
  }

  // Increase the stored count for that choice
  var total = $('.progress-bar').data('total');
  if (type === 'done') {
    window.totals[choice]++;
  } else if (type === 'undo') {
    window.totals[choice]--;
  } else {
    throw new Error("Unknown type " + type + " (should be either 'done' or 'undo'");
  }
  var percent = (window.totals[choice] / total) * 100;

  // Update the progress bar UI
  getProgressBarSegment(choice).animate({
    width: percent + '%'
  }, function(){
    if (percent == 0) {
      $(this).remove();
    }
  });

  // Trigger level completion if grandtotal has been reached
  var grandTotal = 0;
  $.each(window.totals, function(_choice, count) {
    grandTotal = grandTotal + count;
  });
  if (grandTotal === total) {
    levelComplete();
  }
}

var getProgressBarSegment = function getProgressBarSegment(choice){
  // `choice` should be one of: female, male, other, skip
  // Returns the segment element, for chainability.
  // Creates the element if it doesn't already exist.

  var segmentClass = {
    male: 'progress-bar__males',
    other: 'progress-bar__others-dont-knows',
    female: 'progress-bar__females'
  };

  // Maybe the progress bar segment already exists?
  var $el = $('.' + segmentClass[choice]);
  if($el.length){
    return $el;
  }

  var $el = $('<div>').addClass(segmentClass[choice]);

  if(choice === 'male'){
    $el.prependTo('.progress-bar');
  } else if(choice === 'female'){
    $el.appendTo('.progress-bar');
  } else if(choice === 'other' || choice === 'skip'){
    var $elMale = $('.' + segmentClass['male']);
    if($elMale.length){
      $el.insertAfter($elMale);
    } else {
      $el.prependTo('.progress-bar');
    }
  }

  return $el;
}

var filterElements = function filterElements(){
  var $elements = $($(this).attr('data-filter-elements'));
  var searchText = $.trim($(this).val().toLowerCase());

  if(searchText == ''){
    $elements.show();
    return true;
  }

  $elements.each(function(){
    var itemText = $(this).text().toLowerCase();
    var found = itemText.indexOf(searchText) > -1;
    if(found){
      $(this).show();
    } else {
      $(this).hide();
    }
  });
}

var saveResponse = function saveResponse(response) {
  delete response.googleLink;

  return $.ajax({
    url: '/votes',
    method: 'POST',
    data: {
      vote: response
    }
  });
}

var displayClickAnimation = function displayClickAnimation($button){
  $('.js-click-animation', $button).show().animate({
    transform: 'scale(3)',
    opacity: 0
  }, 200, function(){
    $(this).css({
      display: '',
      transform: '',
      opacity: ''
    });
  })
}

$(function(){

  // Animate any messages that have been sent from the server
  if($('.app-messages *').length){
    setTimeout(function(){
      showMessages(3000);
    }, 500);
  }

  if($('.js-cardswipe').length){
    window.onboarding = ( $('.onboarding-page').length > 0 );

    setUpProgressBar();

    $(".js-cardswipe").cardSwipe({
      choices: {
        male: {
          direction: 'left',
          $button: $('.js-choose-male'),
          overlaySelector: '.js-overlay-male'
        },
        female: {
          direction: 'right',
          $button: $('.js-choose-female'),
          overlaySelector: '.js-overlay-female'
        },
        other: {
          direction: 'down',
          $button: $('.js-choose-other'),
          overlaySelector: '.js-overlay-other'
        },
        skip: {
          direction: 'up',
          $button: $('.js-choose-dontknow'),
          overlaySelector: '.js-overlay-dontknow'
        }
      },
      onChoiceMade: function(choice, $card, $button, $stack, animateCurrentCard){
        // Give the user feedback that a choice has been made
        displayClickAnimation($button);

        if(window.onboarding == false) {
          // Save the user's choice
          response = $card.data();
          response.choice = choice;
          saveResponse(response);
        }

        $card.data('choice', choice);

        // While response is being saved, animate and then move the top card
        // to the top of the done stack...
        animateCurrentCard(function(){
          var $doneStack = $('.js-done-stack');
          $card.removeClass('animating').prependTo($doneStack);

          // ...And update the various bits of UI relating to the current card
          updateGoogleLink($stack);
          updateProgressBar(choice);
          updateUndoButton();
        });

        // ...Append a new card to the bottom of the stack...
        var $newCard = $('.js-extra-cards').children().eq(0);
        var $newCardImage = $newCard.find('.js-person__picture');
        $newCardImage.attr('src', $newCardImage.data('src'));
        $newCard.appendTo($stack);

      },
      onKeyboardShortcut: function(direction){
        ga('send', 'event', 'cardSwipe', 'keyboardShortcut', direction);
      },
      onButtonPress: function(direction){
        ga('send', 'event', 'cardSwipe', 'buttonPress', direction);
      },
      onSwipe: function(direction){
        ga('send', 'event', 'cardSwipe', 'swipe', direction);
      },
      onInit: function($stack){
        updateGoogleLink($stack);
        undoInit(this, $stack);
      }
    });

    $('.controls__google a').on('click', function(){
      ga('send', 'event', 'googleThem', 'click');
    });
  }

  $('[data-filter-elements]').on('keyup', filterElements).one('focus', function(){
    var label = $('label[for="' + $(this).attr('id') + '"]').text();
    ga('send', 'event', 'filterElements', 'focus', label);
  });

});
